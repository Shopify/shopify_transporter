# Transporter Tools

The Transporter tool converts data from a third-party platform format into a format that can be imported into Shopify. This tool converts CSV exports from third-party platforms into a CSV format that the Transporter app supports.

The Transporter tool and app are available to Shopify Plus plans only.


## Export from your third-party platform

You need to export your product, customer, and order objects from the third-party platform into separate CSV files. Name each file so that it includes the name of the third-party platform and the object type that you exported (for example, _magento_customers.csv_).



## Installation

Install the Transporter tool gem:

```$ gem install [download_directory]/shopify_transporter.gem```

After you install the gem, you should find the executable `shopify_transporter` available in your path:

```
$ which shopify_transporter
/usr/local/bin/shopify_transporter
```
## Help and usage

To view the usage and help for the `shopify_transporter` run the following command:
```
$ shopify_transporter -h

Commands:
  shopify_transporter convert --config=CONFIG --object=OBJECT file1.csv file2.csv ... # Converts your files into shopify formatted files.
  shopify_transporter generate STAGE_NAME --object=OBJECT                             # Generates a new pipeline stage for the specified object type
  shopify_transporter help [COMMAND]                                                  # Describe available commands or one specific command
  shopify_transporter new PROJECTNAME --platform=PLATFORM                             # Generates a new project structure for a platform
```

## Create a conversion project

You need to create a conversion project for each store that you want to migrate to Shopify.

To create a new conversion project use the `new` sub-command:

```
$ shopify_transporter new example-magento-conversion --platform=magento
      create  example_magento_migration/Gemfile
      create  example_magento_migration/config.yml
      create  example_magento_migration/lib/magento/custom_pipeline_stages
```

The `new` sub-command creates the following objects:

* a `Gemfile` that references the `shopify_transporter` gem. This Gemfile allows custom pipeline stages to refer to the base classes that are defined in the `shopify_transporter` gem.

* a configuration file (_config.yml_) that
provides the configuration required for each pipeline stage in the conversion process.

* a project directory that is named after the project (for example, `example_magento_migration`)

Switch to the project directory. For example:
```cd example_magento_migration```

As with any Ruby project, you need to run the following command before you create and run any custom pipeline stages:

```$ bundle install```


Move the third-party platform CSV file into the conversion project directory. For example: ```example_magento_migration/magento_customers.csv```

## Convert records from the third-party platform to Shopify

Run 'shopify_transporter' and use the `convert` command to convert your objects from the third-party platform to the Shopify format. For example, the following command converts a CSV file that contains customers (_magento_customers.csv_) from Magento to Shopify:

```
shopify_transporter convert --config=config.yml --object=customer magento_customers.csv > shopify_customers.csv
```

In this example, the converted customer objects are saved to  _shopify_customers.csv_. If errors occur during the conversion, then they appear in your terminal.

## Convert multiple files

To convert multiple files to Shopify, separate the file names with a space:

```
shopify_transporter convert --config=config.yml --object=customer magento_customers_1.csv magento_customers_2.csv ...
```

## Configuration file (_config.yml_)

The configuraton file (_config.yml_) is generated when you create your conversion project. This file is specific to the third-party platform that you are converting to Shopify.

Here's an example of a _config.yml_ file for converting customers from Magento:

```
platform_type: Magento
object_types:
  customer:
    record_key: email
    pipeline_stages:
      - TopLevelAttributes
      - AddressesAttribute
      - Metafields:
        type: all_platforms
        params:
          # Specify a custom namespace for your metafields with metafield_namespace.
          # Uses migrated_data by default.
          # metafield_namespace: migrated_data
          metafields:
            - website
            - group
            - free_trial_start_at
```

### record_key

The `config.yml` file allows you to define the object type to convert. An object type needs a `record_key`, whose values must be unique among the other records in the file. For example, the default `record_key` for customers is the customer's email address.
```
platform_type: Magento
object_types:
  customer:
    record_key: email
    ...
```

When you run `shopify_transporter` with the `convert` command, the input (third-party platform) files are read one-by-one and  line-by-line.  Each object in the input file must have a `record_key` value. Rows that have the same `record_key` value are considered to be part of the same object.

### Pipeline_stages

The Transporter tool processes the input (third-party platform objects) through a series of pipeline stages. These stages, and the order in which they are to be processed, are defined in the _config.yml_ file.

In the example below, there are two pipeline stages for converting objects from Magento to Shopify: TopLevelAttributes and AddressAttributes.

```
platform_type: Magento
object_types:
  customer:
    record_key: email
    pipeline_stages:
      - TopLevelAttributes
      - AddressesAttribute
```

Each pipeline stage's _convert_ method receives the row currently being processed, as well as the current state of the corresponding Shopify object being converted. The method's responsibility is to inject into the Shopify object the relevant attributes from the input row.

The role of a pipeline stage is to examine the input rows and populate attributes on the Shopify object. For example, the `TopLevelAttributes` stage of a Magento customer migration looks for a column named `firstname` on the input, and then populates the Shopify object accordingly:


```
record['first_name'] = input['firstname']
```

Any changes that are made to the this record in a pipeline stage are permanent to the Shopify record associated with the `record_key`.

The next pipeline stage that receives this record, receives the same input and the existing record which consist of:

```
{
   'first_name' => 'John',
}
```

Existing pipeline stages and the attributes are populated below.

### Magento v1.x customer


### AddressesAttribute

Addresses are built from the `shipping_` and `billing_` prefixed fields.  The Shopify object's `addresses` attribute
is an array that consists of the `shipping_` prefixed attributes as the first address, and the `billing_` prefixed
attributes as the second.

```
{
   'addresses': [
      {
        'first_name': ...,
        'last_name': ...,
        'address1': ...,
        'address2': ...,
        'city': ...,
        'province': ...,
        'country_code': ...,
        'zip': ...,
        'company': ...,
        'phone': ...,
      },
   ]
}
```

### Metafields

See the metafields section in the All Platforms section below.

### All Platforms

Some stages are a little more versatile and can support input rows from arbitrary third-party platforms.  These stages
are usually extensible through defining parameters in the `config.yml`.

#### Metafields

The `convert` command converts the most popular metafields or custom fields from the third-party platforms into
Shopify [metafields](https://help.shopify.com/manual/products/metafields). You can view the default metafields and
add others in your _config.yml_ file.

## Adding customized stages

If the Shopify object that is generated is missing attributes or if a pipeline stage fails, it could be because there are
unexpected headers defined in the third-party CSV data.

To define your own customized stages, run the following command:

`shopify_transporter generate YourCustomStage --object customer`

A file named `your_custom_stage.rb` is added to the **lib/magento/custom_pipeline_stages** directory. You can modify this file to add your custom conversion logic.

## Limitations

The `convert` command currently only converts customer objects that have been exported from Magento.

## Running unit tests

We use rspec to run our test suite:
`bundle exec rspec`

## Running the linter

It's important that all of the code introduced passes linting. To run it manually:
`bundle exec rake rubocop`
To automatically resolve any basic linting issues:
`bundle exec rake rubocop:autocorrect`

## Building the gem manually
`bundle exec rake build`
