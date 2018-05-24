# Magento v1.x Export Scripts

These are some sample scripts that demonstrate how objects can be exported from Magento.

These command line tools look for specific environment variables that describe the Magento system being exported from then use the SOAP API to retrieve data and display JSON formatted data to the console/standard out.

This output data is properly formatted to be supported as input into the Shopify Transporter Tool which then gets converted into CSV format used for uploading to the [Shopify Transporter App](https://apps.shopify.com/transporter).

## Supported Versions

These sample scripts currently target Magento version 1.x and use the SOAP API.  You will need to ensure that you have a service account with a password capable of connecting to the Magento API before you begin.

## Setting up your environment

To keep things simple and secure these sample scripts read environment variables for the input required to connect to Magento.

### Required 

These environment variables are required or the script will exit early with an error message:

* `MAGENTO_SOAP_API_HOSTNAME`: The hostname of the Magento system
* `MAGENTO_SOAP_API_USERNAME`: The username of the service account used to connect to the SOAP API
* `MAGENTO_SOAP_API_KEY`: The API key used to authenticate against the SOAP API
* `MAGENTO_STORE_ID`: The store ID for multi-store Magento instances to extract data from

### Optional

These variables are not required but can be used to customize the extraction process:

* `LAST_INCREMENT_ID`: The increment ID to resume extracting from in case the script is interrupted and needs to be restarted

### Setting environment variables

On a Unix-like system you can set environment variables using the export command:

```
export MAGENTO_SOAP_API_HOSTNAME=www.mystore.com
export MAGENTO_SOAP_API_USERNAME=soapuser
export MAGENTO_SOAP_API_KEY=sa231lds8asdf90121
export MAGENTO_STORE_ID=1
```

Of course, you will need to ensure you're using the appropriate values.  

These environment variables will last the duration of your terminal or console session.  If you leave your terminal then you will need to redefine them.

## Installing Required Gems

The scripts are very light-weight and only have a single requirement: the [Savon SOAP library](http://savonrb.com/).

You can install the gem with:

```
gem install savon
```

After which you will be able to execute the scripts.

## Executing the extraction scripts

Once you have defined your environment variables you can point ruby at the object script you want to run:

```
ruby customers.rb
```

Depending on the number of objects there will be an initial delay while the collection of objects is being fetched before they are displayed to the console output.

For 50, 000 objects it could take up to 5-10 minutes before the JSON data starts to be displayed.

## Redirecting into a file

Until these scripts are enhanced to support specifying an output file you can redirect your console output from the script into a file using the `>` redirection approach.

```
ruby customers.rb > magento_customers.rb
```

Afterwards, inspect that file to ensure that it contains valid JSON data and that the script didn't prematurely exit with a connection or other error.

## Resuming

In the event that your export is interrupted, you can resume from where you left off by defining the optional `LAST_INCREMENT_ID` environment variable.

*NOTE*: These scripts can take several hours to run for larger shops and are not yet capable of making concurrent requests.  Future versions may address this by performing some API calls in parallel.

## Final steps

Once you've generated your file you can use the Transporter Tools and follow the included documentation for getting started transforming the data into Shopify.
