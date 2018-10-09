# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/exporters/magento/product_options'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        let(:mock_product_options) { double('product options') }

        context '#key' do
          it 'returns :product_id' do
            expect(DatabaseTableExporter).to receive(:new)
            expect(DatabaseCache).to receive(:new)
            expect(ProductOptions).to receive(:new)
            expect(described_class.new.key).to eq(:product_id)
          end
        end

        describe '#export' do
          it 'retrieves configurable products from Magento using the SOAP API and returns the results' do
            soap_client = double('soap client')

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')
            catalog_product_attribute_media_list_response_body = double('catalog_product_attribute_media_list_response_body')
            catalog_product_tag_list_response_body = double('catalog_product_tag_list_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :catalog_product_list,
                batch_index_column: 'product_id',
              )
              .and_return([catalog_product_list_response_body])

            expect(catalog_product_list_response_body).to receive(:body).and_return(
              catalog_product_list_response: {
                store_view: {
                  item: {
                    product_id: '12345',
                    type: 'configurable',
                    top_level_attribute: 'an_attribute',
                  },
                },
              },
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_info, product_id: '12345', attributes: nil)
              .and_return(catalog_product_info_response_body)

            expect(catalog_product_info_response_body).to receive(:body).and_return(
              catalog_product_info_response: {
                info: {
                  "another_key": "another_attribute"
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

            expect(ProductOptions).to receive(:new).and_return(mock_product_options)
            expect(mock_product_options).to receive(:shopify_option_names).and_return({})

            expected_result = {
              product_id: '12345',
              type: 'configurable',
              top_level_attribute: "an_attribute",
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
            }

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
          end

          context 'when product details are unretrievable' do
            it 'returns the product without product details and warns the user' do
              soap_client = double('soap client')

              catalog_product_list_response_body = double('catalog_product_list_response_body')
              catalog_product_info_response_body = double('catalog_product_info_response_body')
              catalog_product_attribute_media_list_response_body = double('catalog_product_attribute_media_list_response_body')

              expect(soap_client)
                .to receive(:call_in_batches)
                .with(
                  method: :catalog_product_list,
                  batch_index_column: 'product_id',
                )
                .and_return([catalog_product_list_response_body])

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: {
                      product_id: '12345',
                      type: 'configurable',
                      top_level_attribute: 'an_attribute',
                    },
                  },
                },
              )

              expect(soap_client)
                .to receive(:call).with(:catalog_product_info, product_id: '12345', attributes: nil)
                .and_return(catalog_product_info_response_body)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                catalog_product_info_response: {
                  info: {
                    "another_key": "another_attribute"
                  }
                }
              )

              expect(soap_client)
                .to receive(:call).with(:catalog_product_attribute_media_list, product: 12345)
                .and_return(catalog_product_attribute_media_list_response_body)

              allow(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
                catalog_product_attribute_media_list_response: { result: { item: [] } }
              )

              expect(soap_client)
                .to receive(:call).with(:catalog_product_tag_list, product_id: 12345)
                .and_raise(Savon::Error)

              expect(ProductOptions).to receive(:new).and_return(mock_product_options)

              expected_result = {
                product_id: '12345',
                type: 'configurable',
                top_level_attribute: "an_attribute",
              }

              exporter = described_class.new(soap_client: soap_client)
              expect do |block|
                stderr = capture(:stderr) { exporter.export(&block) }
                output = <<~WARNING
                  ***
                  Warning:
                  Encountered an error with fetching details for product with id: 12345
                  {
                    "product_id": "12345",
                    "type": "configurable",
                    "top_level_attribute": "an_attribute"
                  }
                  The exact error was:
                  Savon::Error: 
                  Savon::Error
                  -
                  Exporting the product (12345) without its details.
                  Continuing with the next product.
                  ***
                WARNING
                expect(stderr).to eq(output)
              end.to yield_with_args(expected_result)
            end
          end

          it 'works when multiple products are returned by the soap call' do
            soap_client = double('soap client')

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')
            catalog_product_attribute_media_list_response_body = double('catalog_product_attribute_media_list_response_body')
            catalog_product_tag_list_response_body = double('catalog_product_tag_list_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :catalog_product_list,
                batch_index_column: 'product_id',
              )
              .and_return([catalog_product_list_response_body])

            expect(catalog_product_list_response_body).to receive(:body).and_return(
              catalog_product_list_response: {
                store_view: {
                  item: [
                    {
                      product_id: '10',
                      type: 'configurable',
                      top_level_attribute: 'product1',
                    },
                    {
                      product_id: '11',
                      type: 'configurable',
                      top_level_attribute: 'product2',
                    },
                  ]
                },
              },
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_info, product_id: '10', attributes: nil)
              .and_return(catalog_product_info_response_body)

            expect(soap_client)
              .to receive(:call).with(:catalog_product_info, product_id: '11', attributes: nil)
              .and_return(catalog_product_info_response_body)

            allow(catalog_product_info_response_body).to receive(:body).and_return(
              catalog_product_info_response: {
                info: {
                  "another_key": "another_attribute"
                }
              }
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_attribute_media_list, product: 10)
              .and_return(catalog_product_attribute_media_list_response_body)
            expect(soap_client)
              .to receive(:call).with(:catalog_product_attribute_media_list, product: 11)
              .and_return(catalog_product_attribute_media_list_response_body)

            allow(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
              catalog_product_attribute_media_list_response: { result: { item: [] } }
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_tag_list, product_id: 10)
                    .and_return(catalog_product_tag_list_response_body)
            expect(soap_client)
              .to receive(:call).with(:catalog_product_tag_list, product_id: 11)
                    .and_return(catalog_product_tag_list_response_body)

            allow(catalog_product_tag_list_response_body).to receive(:body).and_return(
              catalog_product_tag_list_response: { result: { item: [ ] } }
            )

            expect(ProductOptions).to receive(:new).and_return(mock_product_options)
            expect(mock_product_options).to receive(:shopify_option_names).and_return({}).twice

            expected_result = [
              {
                product_id: '10',
                type: 'configurable',
                top_level_attribute: 'product1',
                images: [],
                another_key: 'another_attribute',
                tags: []
              },
              {
                product_id: '11',
                type: 'configurable',
                top_level_attribute: 'product2',
                images: [],
                another_key: 'another_attribute',
                tags: []
              },
            ]

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_successive_args(*expected_result)
          end

          describe 'simple products' do
            let(:soap_client) { double('soap client') }

            let(:catalog_product_list_response_body) { double('catalog_product_list_response_body') }
            let(:catalog_product_info_response_body) { double('catalog_product_info_response_body') }
            let(:catalog_inventory_stock_item_list_response_body) { double('catalog_inventory_stock_item_list_response_body') }
            let(:catalog_product_attribute_media_list_response_body) do
              double('catalog_product_attribute_media_list_response_body')
            end
            let(:catalog_product_tag_list_response_body) { double('catalog_product_tag_list_response_body') }

            def setup_soap_response_for_single_product
              stub_options_to_return_nothing

              expect(soap_client)
                .to receive(:call_in_batches)
                .with(
                  method: :catalog_product_list,
                  batch_index_column: 'product_id',
                )
                .and_return([catalog_product_list_response_body])

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: {
                      product_id: '801',
                      type: 'simple',
                      top_level_attribute: "an_attribute",
                    },
                  },
                }
              ).at_least(:once)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: {
                    info: {
                      "another_key": "another_attribute"
                    }
                  }
              ).at_least(:once)
            end

            def stub_options_to_return_nothing
              allow(ProductOptions).to receive(:new).and_return(mock_product_options)
              allow(mock_product_options).to receive(:shopify_option_names).and_return({})
              allow(mock_product_options).to receive(:lowercase_option_names).and_return([])
              allow(mock_product_options).to receive(:shopify_variant_options).and_return({})
            end

            def stub_tags_to_return_nothing
              allow(soap_client)
                .to receive(:call).with(:catalog_product_tag_list, anything)
                .and_return(catalog_product_tag_list_response_body)

              allow(catalog_product_tag_list_response_body).to receive(:body).and_return(
                catalog_product_tag_list_response: { result: { item: [] } }
              )
            end

            def stub_inventory_to_return_five
              allow(soap_client)
                .to receive(:call).with(:catalog_inventory_stock_item_list, anything)
                .and_return(catalog_inventory_stock_item_list_response_body)

              allow(catalog_inventory_stock_item_list_response_body).to receive(:body).and_return(
                catalog_inventory_stock_item_list_response: { result: { item: { qty: 5 } } }
              )
            end

            it 'retrieves simple products from Magento using the SOAP API and injects parent_id' do
              setup_soap_response_for_single_product

              expect(soap_client)
                .to receive(:call).with(
                  :catalog_product_info,
                  product_id: '801',
                  attributes: {
                    'additional_attributes' => {
                      item: [],
                    },
                  }
                )
                .and_return(catalog_product_info_response_body)

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

              expected_result = {
                product_id: '801',
                top_level_attribute: "an_attribute",
                type: 'simple',
                parent_id: '12345',
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
              }

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

              exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
              expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
            end

            it 'retrieves simple products from Magento and does not inject parent_id if the parent_id does not exist' do
              setup_soap_response_for_single_product

              expect(soap_client)
                .to receive(:call).with(
                  :catalog_product_info,
                  product_id: '801',
                  attributes: nil,
                )
                .and_return(catalog_product_info_response_body)

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

              expected_result = {
                product_id: '801',
                type: 'simple',
                top_level_attribute: "an_attribute",
                inventory_quantity: 5,
                another_key: "another_attribute",
                images: [{ url:  :img_src }, { url:  :img_src2 }],
                tags: [
                  {
                    tag_id: "17",
                    name: "white",
                    "@xsi:type": "ns1:catalogProductTagListEntity"
                  },
                  {
                    tag_id: "18",
                    name: "shirt",
                    "@xsi:type": "ns1:catalogProductTagListEntity"
                  }
                ]
              }

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

              exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
              expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
            end

            it 'only calls the database exporter once' do
              expect(soap_client)
                .to receive(:call_in_batches)
                .with(
                  method: :catalog_product_list,
                  batch_index_column: 'product_id',
                )
                .and_return([catalog_product_list_response_body])

              allow(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: [
                      {
                        product_id: '801',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                      {
                        product_id: '802',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                    ],
                  },
                }
              )

              allow(soap_client)
                .to receive(:call).with(:catalog_product_attribute_media_list, anything)
                .and_return(catalog_product_attribute_media_list_response_body)

              allow(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
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

              expect(soap_client).to receive(:call).with(
                :catalog_product_info, product_id: '801', attributes: nil
              ).and_return(catalog_product_info_response_body)

              expect(soap_client).to receive(:call).with(
                :catalog_product_info, product_id: '802', attributes: nil
              ).and_return(catalog_product_info_response_body)

              allow(catalog_product_info_response_body).to receive(:body).and_return(
                catalog_product_info_response: {
                  info: {
                    "another_key": "another_attribute"
                  }
                }
              )

              expect_any_instance_of(DatabaseTableExporter).to receive(:export_table).with(
                'catalog_product_relation',
                'parent_id'
              ).once

              expect_any_instance_of(DatabaseCache).to receive(:table).with('catalog_product_relation').and_return([])

              stub_tags_to_return_nothing
              stub_inventory_to_return_five
              stub_options_to_return_nothing

              exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
              exporter.export {}
            end

            describe 'processing options' do
              before :each do
                allow(soap_client)
                  .to receive(:call_in_batches)
                  .with(
                    method: :catalog_product_list,
                    batch_index_column: 'product_id',
                  )
                  .and_return([catalog_product_list_response_body])

                allow(soap_client)
                  .to receive(:call).with(:catalog_product_attribute_media_list, anything)
                  .and_return(catalog_product_attribute_media_list_response_body)

                allow(catalog_product_attribute_media_list_response_body).to receive(:body).and_return(
                  catalog_product_attribute_media_list_response: { result: { item: [] } }
                )

                stub_inventory_to_return_five
                stub_tags_to_return_nothing

                allow(ProductOptions).to receive(:new).and_return(mock_product_options)
              end

              it 'extracts product option names for configurable products' do
                expect(soap_client)
                  .to receive(:call).with(:catalog_product_info, anything)
                  .and_return(catalog_product_info_response_body)

                expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: { info: {} }
                )

                expect(mock_product_options).to receive(:shopify_option_names).with('801').and_return(
                  option1_name: 'Color',
                  option2_name: 'Size'
                )

                expect(catalog_product_list_response_body).to receive(:body).and_return(
                  catalog_product_list_response: {
                    store_view: {
                      item: {
                        product_id: '801',
                        type: 'configurable',
                      },
                    },
                  }
                ).at_least(:once)

                expected_result = {
                  product_id: '801',
                  images: [],
                  tags: [],
                  type: 'configurable',
                  option1_name: 'Color',
                  option2_name: 'Size',
                }

                exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
                expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
              end

              it 'extracts product option names and values for simple products' do
                expect_any_instance_of(DatabaseTableExporter).to receive(:export_table)

                expect_any_instance_of(DatabaseCache).to receive(:table).with('catalog_product_relation').and_return([{
                    'parent_id' => '801',
                    'child_id' => '802',
                  }
                ])

                expect(mock_product_options).to receive(:lowercase_option_names).with('801').and_return(
                  ['color', 'size']
                )

                expect(mock_product_options).to receive(:shopify_variant_options).with(
                  {
                    product_id: '802',
                    images: [],
                    tags: [],
                    type: 'simple',
                    parent_id: '801',
                    another_attribute: 'another_value',
                    additional_attributes: {
                      item: [
                        {
                          key: 'color',
                          value: '22',
                        },
                        {
                          key: 'size',
                          value: '47',
                        },
                      ]
                    },
                  }
                ).and_return(
                  option1_name: 'Color',
                  option1_value: 'White',
                  option2_name: 'Size',
                  option2_value: 'XS'
                )

                expect(catalog_product_list_response_body).to receive(:body).and_return(
                  catalog_product_list_response: {
                    store_view: {
                      item: {
                        product_id: '802',
                        type: 'simple',
                      },
                    },
                  }
                ).at_least(:once)

                expect(soap_client).to receive(:call)
                  .with(
                    :catalog_product_info,
                    product_id: '802',
                    attributes: {
                      'additional_attributes' => { item: ['color', 'size'] }
                    }
                  )
                  .and_return(catalog_product_info_response_body)

                expect(catalog_product_info_response_body).to receive(:body)
                  .and_return(
                    catalog_product_info_response: {
                      info: {
                        product_id: '802',
                        another_attribute: 'another_value',
                        additional_attributes: {
                          item: [
                            {
                              key: 'color',
                              value: '22',
                            },
                            {
                              key: 'size',
                              value: '47',
                            },
                          ]
                        },
                      },
                    }
                )

                expected_result = {
                  product_id: '802',
                  type: 'simple',
                  parent_id: '801',
                  images: [],
                  tags: [],
                  another_attribute: 'another_value',
                  inventory_quantity: 5,
                  option1_name: 'Color',
                  option1_value: 'White',
                  option2_name: 'Size',
                  option2_value: 'XS',
                  additional_attributes: {
                    item: [
                      {
                        key: 'color',
                        value: '22',
                      },
                      {
                        key: 'size',
                        value: '47',
                      },
                    ]
                  },
                }

                exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
                expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
              end

              it 'does not extract product option names and values for simple products without a parent' do
                expect_any_instance_of(DatabaseTableExporter).to receive(:export_table)

                expect_any_instance_of(DatabaseCache).to receive(:table).with('catalog_product_relation').and_return([])

                expect(catalog_product_list_response_body).to receive(:body).and_return(
                  catalog_product_list_response: {
                    store_view: {
                      item: {
                        product_id: '802',
                        type: 'simple',
                      },
                    },
                  }
                ).at_least(:once)

                expect(soap_client).to receive(:call)
                  .with(
                    :catalog_product_info,
                    product_id: '802',
                    attributes: nil
                  )
                  .and_return(catalog_product_info_response_body)

                expect(catalog_product_info_response_body).to receive(:body)
                  .and_return(
                    catalog_product_info_response: {
                      info: {
                        product_id: '802',
                        another_attribute: 'another_value',
                      },
                    }
                )

                expect(mock_product_options).to receive(:shopify_variant_options).with(
                  {
                    product_id: '802',
                    images: [],
                    tags: [],
                    type: 'simple',
                    another_attribute: 'another_value',
                  }
                ).and_return({})

                expected_result = {
                  product_id: '802',
                  type: 'simple',
                  images: [],
                  tags: [],
                  another_attribute: 'another_value',
                  inventory_quantity: 5,
                }

                exporter = described_class.new(soap_client: soap_client, database_adapter: nil)
                expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
              end
            end
          end
        end
      end
    end
  end
end
