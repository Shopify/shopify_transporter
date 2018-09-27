# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        context '#run'
          it 'retrieves configurable products from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')
            catalog_product_attribute_media_list_response_body = double('catalog_product_attribute_media_list_response_body')
            catalog_product_tag_list_response_body = double('catalog_product_tag_list_response_body')

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
                      top_level_attribute: "an_attribute",
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

            expect(soap_client)
              .to receive(:call).with(:catalog_product_tag_list, product_id: 12345)
                    .and_return(catalog_product_tag_list_response_body)

            expect(catalog_product_tag_list_response_body).to receive(:body).and_return(
              catalog_product_tag_list_response: {
                result: {
                  item: [
                    {
                      "tag_id": "17",
                      "name": "white",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
                    },
                    {
                      "tag_id": "18",
                      "name": "shirt",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
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
                images: [{ url: :img_src }, { url: :img_src2 }],
                tags: [
                  {
                    "tag_id": "17",
                    "name": "white",
                    "@xsi:type": "ns1:catalogProductTagListEntity"
                  },
                  {
                    "tag_id": "18",
                    "name": "shirt",
                    "@xsi:type": "ns1:catalogProductTagListEntity"
                  }
                ]
              },
            ]

            exporter = described_class.new(soap_client: soap_client)
            expect(exporter.export).to eq(expected_result)
          end

          context '#parent_id' do
            let(:soap_client) { double("soap client") }
            let(:product_mapping_exporter) { double("product_mapping_exporter") }

            let(:catalog_product_list_response_body) { double('catalog_product_list_response_body') }
            let(:catalog_product_info_response_body) { double('catalog_product_info_response_body') }
            let(:catalog_inventory_stock_item_list_response_body) { double('catalog_inventory_stock_item_list_response_body') }
            let(:catalog_product_attribute_media_list_response_body) do
              double('catalog_product_attribute_media_list_response_body')
            end
            let(:catalog_product_tag_list_response_body) { double('catalog_product_tag_list_response_body') }

            it 'retrieves simple products from Magento using the SOAP API and injects parent_id' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)


              expect(ProductMappingExporter).to receive(:new).and_return(product_mapping_exporter)
              expect(product_mapping_exporter).to receive(:write_mappings)

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

              expect(soap_client)
                .to receive(:call).with(:catalog_product_tag_list, product_id: 801)
                      .and_return(catalog_product_tag_list_response_body)

              expect(catalog_product_tag_list_response_body).to receive(:body).and_return(
                catalog_product_tag_list_response: {
                  result: {
                    item: [
                      {
                        "tag_id": "17",
                        "name": "white",
                        "@xsi:type": "ns1:catalogProductTagListEntity"
                      },
                      {
                        "tag_id": "18",
                        "name": "shirt",
                        "@xsi:type": "ns1:catalogProductTagListEntity"
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
                  images: [{ url: :img_src }, { url: :img_src2 }],
                  tags: [
                    {
                      "tag_id": "17",
                      "name": "white",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
                    },
                    {
                      "tag_id": "18",
                      "name": "shirt",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
                    }
                  ]
                },
              ]

              mappings = <<~EOS
                product_id,associated_product_id
                12345,800
                12345,801
                12345,802
                67890,900
                67890,901
              EOS

              in_temp_folder do
                File.open('magento_product_mappings.csv', 'w') { |file| file.write(mappings) }
                exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
                expect(exporter.export).to eq(expected_result)
              end
            end

            it 'retrieves simple products from Magento and does not inject parent_id if the parent_id does not exist' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)

              expect(soap_client)
                  .to receive(:call).with(:catalog_product_info, product_id: '801')
                          .and_return(catalog_product_info_response_body)

              expect(ProductMappingExporter).to receive(:new).and_return(product_mapping_exporter)
              expect(product_mapping_exporter).to receive(:write_mappings)

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
                .to receive(:call).with(:catalog_product_tag_list, product_id: 801)
                      .and_return(catalog_product_tag_list_response_body)

              expect(catalog_product_tag_list_response_body).to receive(:body).and_return(
                catalog_product_tag_list_response: {
                  result: {
                    item: [
                      {
                        "tag_id": "17",
                        "name": "white",
                        "@xsi:type": "ns1:catalogProductTagListEntity"
                      },
                      {
                        "tag_id": "18",
                        "name": "shirt",
                        "@xsi:type": "ns1:catalogProductTagListEntity"
                      }
                    ]
                  }
                })

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
                  tags: [
                    {
                      "tag_id": "17",
                      "name": "white",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
                    },
                    {
                      "tag_id": "18",
                      "name": "shirt",
                      "@xsi:type": "ns1:catalogProductTagListEntity"
                    }
                  ]
                },
              ]

              mappings = <<~EOS
                product_id,associated_product_id
                ,800
                ,801
                ,802
                67890,900
                67890,901
              EOS

              in_temp_folder do
                File.open('magento_product_mappings.csv', 'w') { |file| file.write(mappings) }
                exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
                expect(exporter.export).to eq(expected_result)
              end
            end
          end
        end
    end
  end
end
