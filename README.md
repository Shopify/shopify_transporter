# Shopify Transporter

`shopify_transporter` is a command-line tool that offers capabilities to extract and convert data from third-party platforms into a Shopify-friendly format.

Shopify Transporter offers built-in support for migrations from Magento v1.x, and offers support for you to write your own transformations for other platforms.

This format can then be imported into Shopify via the [Transporter app](https://help.shopify.com/manual/migrating-to-shopify/transporter-app).

*Note: the Transporter app is available to Shopify Plus plans only.*

## Submitting Issues

Please open an issue here if you encounter a specific bug with this library or if something is documented
incorrectly.

When filing an issue, please ensure that:

- The issue is not already covered in another open issue
- The issue does not contain any confidential or personally identifiable information
- The issue is specifically regarding the `shopify_transporter` gem and not related to the Transporter App.

## Installation

### Requirements:
1. Ruby 2.4.0 or higher
2. You are able to install Ruby gems. Please visit [the Bundler website](https://bundler.io/) to troubleshoot issues with installing gems.

We test and support the gem for Mac OS environments. While not officially supported, the gem may work on other operating systems provided they meet the above requirements.

### Installing the Transporter tool gem from rubygems:

```
$ gem install shopify_transporter
```

### Running
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
 shopify_transporter convert FILE_NAMES --object=OBJECT file1.csv file2.csv  # Converts objects into a Shopify-format. (accepts a list of space-separated ...
 shopify_transporter export --object=OBJECT                                  # Exports objects from a third-party platform into a format compatible for co...
 shopify_transporter generate STAGE_NAME --object=OBJECT                     # Generate a custom pipeline stage for the object
 shopify_transporter help [COMMAND]                                          # Describe available commands or one specific command
 shopify_transporter new PROJECTNAME --platform=PLATFORM                     # Generate a project for the platform
```

A typical approach for migrating a store from a third-party platform onto Shopify using the Transporter suite of tools might be:

Create a conversion project for that store
Set up the `config.yml` file
Use the `export` command to download data from the source store
Use the `convert` command to transform that data into a Shopify-formatted CSV file
Use the [Transporter app](https://help.shopify.com/manual/migrating-to-shopify/transporter-app) to import the Shopify-formatted CSV into a Shopify store

### Create a conversion project

It's convenient to create a conversion project for each store that you want to migrate to Shopify.
To create it, use the `new` sub-command:

```
$ shopify_transporter new example-magento-conversion --platform=magento
     create  example_magento_migration/Gemfile
     create  example_magento_migration/config.yml
     create  example_magento_migration/lib/magento/custom_pipeline_stages
```

The `new` sub-command creates a project folder with the following:

* a `Gemfile` that references the `shopify_transporter` gem. This Gemfile allows custom pipeline stages
to refer to the base classes that are defined in the `shopify_transporter` gem.

* a configuration file (`config.yml`) that provides the configuration required for each pipeline stage
in the conversion process.

* a folder to hold additional custom pipeline stages you may define later

Switch to the project directory. For example:

```
cd example_magento_migration
```

As with any Ruby project, you need to run the following command before you create and run any custom
pipeline stages:

```
$ bundle install
```

### Configuration file (_config.yml_)

The configuration file is generated when you create your conversion project. This file is specific to the
third-party platform that you are converting to Shopify.

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

### Export records from the third-party platform

Run `shopify_transporter export` in order to export data from your third-party platform. The following command executes the built-in Magento customer exporter:

```
shopify_transporter export --config=config.yml --object=customer > magento_customers.json
```

In this example, the exported customer objects are saved to *magento_customers.json*.

In order to export data, API credentials must be provided in `config.yml`. For example, to use the built-in Magento exporters, you must enter the following fields:

```
export_configuration:
  soap:
    hostname: your-magento-host.com
    username: your-soap-username
    api_key: your-soap-api-key
```

#### Exporting products from Magento 1.x

To export full product data from Magento 1.x, Shopify Transporter requires a connection to the Magento database in addition to the SOAP API credentials. Here’s an example snippet for exporting products:
```
export_configuration:
  soap:
    hostname: your-magento-host.com
    username: your-soap-username
    api_key: your-soap-api-key
  database:
    host: 123.456.88.99
    port: 3306
    user: root
    password: “”
    database: magento_database_name
```

The `export` command will open connections to the Magento database as well as the Magento SOAP API.

During the export process, data will be cached in a generated `cache/` directory. If the exported data seems out of date, you may need to wipe this folder.

### Convert records from the third-party platform to Shopify

Run `shopify_transporter` and use the `convert` command to convert your objects from the
third-party platform to the Shopify format. For example, the following command converts a
JSON file that contains customers (*magento_customers.json*) from Magento to Shopify:

```
shopify_transporter convert --config=config.yml --object=customer magento_customers.json > shopify_customers.csv
```

In this example, the converted customer objects are saved to *shopify_customers.csv*. If errors occur during the conversion, they will appear in your terminal.

### Convert multiple files

To convert multiple files to Shopify’s format, separate the file names with a space:

```
shopify_transporter convert --config=config.yml --object=customer magento_customers_1.json magento_customers_2.json ...
```

## Advanced

### record_key

The `config.yml` file allows you to define the object type to convert. An object type needs a `record_key`,
whose values must be unique among the other records in the file. For example, the default `record_key` for
customers is the customer's email address.

```
platform_type: Magento
object_types:
 customer:
   record_key: email
   ...
```

When you run `shopify_transporter` with the `convert` command, the input (third-party platform) files are
read one-by-one and line-by-line.  Each object in the input file must have a `record_key` value. Rows that
have the same `record_key` value are considered to be part of the same object.

### Pipeline_stages

The Transporter tool processes the input (third-party platform objects) through a series of pipeline
stages. These stages, and the order in which they are to be processed, are defined in the `config.yml` file.

In the example below, there are two pipeline stages for converting objects from Magento to
Shopify: TopLevelAttributes and AddressAttributes.

```
platform_type: Magento
object_types:
 customer:
   record_key: email
   pipeline_stages:
     - TopLevelAttributes
     - AddressesAttribute
```

Each pipeline stage's _convert_ method receives the row currently being processed, as well as the
current state of the corresponding Shopify object being converted. The method's responsibility is to
inject into the Shopify object the relevant attributes from the input row.

The role of a pipeline stage is to examine the input rows and populate attributes on the Shopify object.
For example, the `TopLevelAttributes` stage of a Magento customer migration looks for a column
named `firstname` on the input, and then populates the Shopify object accordingly:


```
record['first_name'] = input['firstname']
```

Any changes that are made to the this record in a pipeline stage are permanent to the Shopify record
associated with the `record_key`.

The next pipeline stage that receives this record, receives the same input and the existing record which
consist of:

```
{
  'first_name' => 'John',
}
```

Existing pipeline stages and the attributes are populated below.

### Metafields

See the metafields section in the All Platforms section below.

### All Platforms

Some stages are a little more versatile and can support input rows from arbitrary third-party platforms.  These stages
are usually extensible through defining parameters in the `config.yml`.

#### Metafields

The `convert` command converts the most popular metafields or custom fields from the third-party platforms into
Shopify [metafields](https://help.shopify.com/manual/products/metafields). You can view the default metafields and
add others in your `config.yml` file.

## Adding customized stages

If the Shopify object that is generated is missing attributes or if a pipeline stage fails, it could be because there are
unexpected headers defined in the third-party CSV data.

To define your own customized stages, run the following command:

`shopify_transporter generate YourCustomStage --object customer`

A file named `your_custom_stage.rb` is added to the `lib/magento/custom_pipeline_stages` directory. You can modify this file to add your custom conversion logic.

## Limitations

The `convert` command currently only converts customer, product, and order JSON objects that have been exported by SOAP API
from Magento 1.x.

## Contributing

### Running unit tests

We use rspec to run our test suite:
`bundle exec rspec`

### Running the linter

It's important that all of the code introduced passes linting. To run it manually:
`bundle exec rake rubocop`
To automatically resolve any basic linting issues:
`bundle exec rake rubocop:autocorrect`

### Building and installing locally
To build locally run the following command:

```
$ bundle exec rake build

shopify_transporter 1.0.0 built to pkg/shopify_transporter-1.0.0.gem.
```

Then, you can install the gem system-wide by running:

```
$ gem install pkg/shopify_transporter-1.0.0.gem

Successfully installed shopify_transporter-1.0.0
Parsing documentation for shopify_transporter-1.0.0
Installing ri documentation for shopify_transporter-1.0.0
Done installing documentation for shopify_transporter after 0 seconds
1 gem installed
```
Your locally built gem is now installed system-wide.
