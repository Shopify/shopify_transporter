# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        describe '#run' do
          it 'retrieves configurable products from Magento using the SOAP API and returns the results' do
            soap_client = double('soap client')

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')
            catalog_product_attribute_media_list_response_body = double('catalog_product_attribute_media_list_response_body')

            expect(soap_client)
              .to receive(:call).with(:catalog_product_list, anything)
              .and_return(catalog_product_list_response_body)

            expect(catalog_product_list_response_body).to receive(:body).and_return(
              catalog_product_list_response: {
                store_view: {
                  item: [
                    {
                      product_id: '12345',
                      type: 'configurable',
                      top_level_attribute: 'an_attribute',
                    },
                  ],
                },
              },
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_info, product_id: '12345')
              .and_return(catalog_product_info_response_body)

            expect(catalog_product_info_response_body).to receive(:body).and_return(
              catalog_product_info_response: {
                info: {
                  "attribute_key": "another_attribute"
                }
              }
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_attribute_media_list, product: 12345)
              .and_return(catalog_product_attribute_media_list_response_body)

            expect(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
              catalog_product_attribute_media_list_response: {
                result: {
                  item: [
                    {
                      url: :img_src
                    },
                    {
                      url: :img_src2
                    }
                  ]
                }
              }
            )

            expected_result = [
              {
                product_id: '12345',
                type: 'configurable',
                top_level_attribute: "an_attribute",
                attribute_key: "another_attribute",
                images: [{ url: :img_src }, { url: :img_src2 }]
              },
            ]

            exporter = described_class.new(store_id: 1, soap_client: soap_client)
            expect(exporter.export).to eq(expected_result)
          end

          describe '#parent_id' do
            let(:soap_client) { double('soap client') }

            let(:catalog_product_list_response_body) { double('catalog_product_list_response_body') }
            let(:catalog_product_info_response_body) { double('catalog_product_info_response_body') }
            let(:catalog_inventory_stock_item_list_response_body) { double('catalog_inventory_stock_item_list_response_body') }
            let(:catalog_product_attribute_media_list_response_body) do
              double('catalog_product_attribute_media_list_response_body')
            end

            it 'retrieves simple products from Magento using the SOAP API and injects parent_id' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: [
                      {
                        product_id: '801',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                    ],
                  },
                }
              ).at_least(:once)

              expect(soap_client)
                .to receive(:call).with(:catalog_product_info, product_id: '801')
                .and_return(catalog_product_info_response_body)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: {
                    info: {
                      "attribute_key": "another_attribute"
                    }
                  }
              ).at_least(:once)

              expect(soap_client)
                .to receive(:call).with(:catalog_inventory_stock_item_list, {:products=>{:product_id=>"801"}})
                .and_return(catalog_inventory_stock_item_list_response_body)

              expect(catalog_inventory_stock_item_list_response_body).to receive(:body).and_return(
                catalog_inventory_stock_item_list_response: {
                  result: {
                    item: {
                      qty: 5
                    }
                  }
                }
              )

              expect(soap_client)
                .to receive(:call).with(:catalog_product_attribute_media_list, product: 801)
                .and_return(catalog_product_attribute_media_list_response_body)

              expect(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
                catalog_product_attribute_media_list_response: {
                  result: {
                    item: [
                      {
                        url: :img_src
                      },
                      {
                        url: :img_src2
                      }
                    ]
                  }
                }
              )

              expected_result = [
                {
                  product_id: '801',
                  top_level_attribute: "an_attribute",
                  type: 'simple',
                  parent_id: '12345',
                  inventory_quantity: 5,
                  attribute_key: "another_attribute",
                  images: [{ url: :img_src }, { url: :img_src2 }]
                },
              ]

              expect_any_instance_of(DatabaseTableExporter).to receive(:export_table).with(
                'catalog_product_relation',
                'parent_id'
              )

              expect_any_instance_of(DatabaseCache).to receive(:table).with('catalog_product_relation').and_return(
                [
                  {
                    'parent_id' => '12345',
                    'child_id' => '800',
                  },
                  {
                    'parent_id' => '12345',
                    'child_id' => '801',
                  },
                  {
                    'parent_id' => '67890',
                    'child_id' => '912',
                  }
                ]
              )

              exporter = described_class.new(store_id: 1, soap_client: soap_client, database_adapter: nil)
              expect(exporter.export).to eq(expected_result)
            end

            it 'retrieves simple products from Magento and does not inject parent_id if the parent_id does not exist' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)

              expect(soap_client)
                  .to receive(:call).with(:catalog_product_info, product_id: '801')
                          .and_return(catalog_product_info_response_body)

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: [
                      {
                        product_id: '801',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                    ],
                  },
                },
              ).at_least(:once)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: {
                    info: {
                      "another_key": "another_attribute",
                    },
                  }
              ).at_least(:once)

              expect(soap_client)
                .to receive(:call).with(:catalog_product_attribute_media_list, product: 801)
                .and_return(catalog_product_attribute_media_list_response_body)

              expect(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
                catalog_product_attribute_media_list_response: {
                  result: {
                    item: [
                      {
                        url: :img_src
                      },
                      {
                        url: :img_src2
                      }
                    ]
                  }
                }
              )

              expect(soap_client)
                .to receive(:call).with(:catalog_inventory_stock_item_list, {:products=>{:product_id=>"801"}})
                .and_return(catalog_inventory_stock_item_list_response_body)

              expect(catalog_inventory_stock_item_list_response_body).to receive(:body).and_return(
                catalog_inventory_stock_item_list_response: {
                  result: {
                    item: {
                      qty: 5
                    }
                  }
                }
              )

              expected_result = [
                {
                  product_id: '801',
                  type: 'simple',
                  top_level_attribute: "an_attribute",
                  inventory_quantity: 5,
                  another_key: "another_attribute",
                  images: [{ url: :img_src }, { url: :img_src2 }],
                  type: 'simple',
                },
              ]

              expect_any_instance_of(DatabaseTableExporter).to receive(:export_table).with(
                'catalog_product_relation',
                'parent_id'
              )

              expect_any_instance_of(DatabaseCache).to receive(:table).with('catalog_product_relation').and_return(
                [
                  {
                    'product_id' => '12345',
                    'child_id' => '800',
                  },
                  {
                    'product_id' => '67890',
                    'child_id' => '912',
                  }
                ]
              )

              exporter = described_class.new(store_id: 1, soap_client: soap_client, database_adapter: nil)
              expect(exporter.export).to eq(expected_result)
            end
          end
        end
      end
    end
  end
end
