# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

RSpec.describe ShopifyTransporter do
  def tmpfile(content)
    (ext, content) = if content.is_a?(String)
      ['.csv', content]
    else
      content = [content] unless content.is_a? Array
      ['.json', content.to_json]
    end
    file = Tempfile.new(['test', ext])
    file.puts content
    file.close
    file
  end

  context '#version' do
    it "has a version number" do
      expect(ShopifyTransporter::VERSION).not_to be nil
    end
  end

  context '#initialize' do
    context 'with invalid entries' do
      it 'fails gracefully with an output to stdout when given files that do no exist' do
        files = ['something.csv']
        config = 'spec/files/config.yml'
        expect { TransporterTool.new(*files, config, 'customer') }.to output("File something.csv can't be found\n").to_stdout
      end

      it 'fails and requires a valid config.yml' do
        files = ['spec/files/blank.csv']
        config = 'invalid.yml'
        expect { TransporterTool.new(*files, config, 'customer') }.to output("File invalid.yml can't be found\n").to_stdout
      end
    end

    context 'with custom pipeline stages' do
      it 'attempts to load the class from the custom namespace' do
        files = ['spec/files/blank.csv']
        config = 'spec/files/config-with-custom-stage.yml'

        stage_class = double('custom_stage')

        expect(Object).to receive(:const_get)
        expect(Object).to receive(:const_get).once.with('CustomPipeline::Customer::CustomStage').and_return(stage_class)
        expect { TransporterTool.new(*files, config, 'customer') }.to raise_error(TransporterTool::StageNotFoundError)
      end

      it 'raises an error when a stage cannot be found' do
        files = ['spec/files/blank.csv']
        config = 'spec/files/config-with-custom-stage.yml'
        expect { TransporterTool.new(*files, config, 'customer') }.to raise_error(
          TransporterTool::StageNotFoundError, "Unable to find stage named 'CustomStage'"
        )
      end
    end

    it 'raises an error when a supported object type cannot be found' do
      files = ['spec/files/blank.csv']
      config = 'spec/files/config.yml'
      object_type = 'invalid_object_type'
      expect { TransporterTool.new(*files, config, object_type) }.to raise_error(
        TransporterTool::InvalidObjectType, "Unable to find object type named: 'invalid_object_type' in config.yml." \
                                            "Are you sure 'invalid_object_type' is listed in the config.yml?"
      )
    end

    it 'raises an error when a pipeline stage type is not supported' do
      files = ['spec/files/blank.csv']
      config = 'spec/files/config-with-unsupported-stage-type.yml'
      expect { TransporterTool.new(*files, config, 'customer') }.to raise_error(
        TransporterTool::UnsupportedStageTypeError, "Stage: 'UnsupportedStage' has an unsupported type: 'unsupported'." \
          " It must be one of 'default', 'custom' or 'all_platforms'"
      )
    end

    it 'looks in the default namespace for namespaces that are specified as strings' do
      files = ['spec/files/blank.csv']
      config = 'spec/files/config.yml'

      allow(Object).to receive(:const_get).with('ShopifyTransporter::Shopify::Customer')
      expect(Object).to receive(:const_get).once.with('ShopifyTransporter::Pipeline::Magento::Customer::TopLevelAttributes').and_call_original

      TransporterTool.new(*files, config, 'customer')
    end

    it 'looks in the default namespace when a type is not specified' do
      files = ['spec/files/blank.csv']
      config = 'spec/files/config-with-unspecified-stage-type.yml'

      mock_stage_class = double("mock_stage_class")

      allow(Object).to receive(:const_get).with('ShopifyTransporter::Shopify::Customer')
      expect(Object).to receive(:const_get).once.with('ShopifyTransporter::Pipeline::Magento::Customer::StageDefinedAsHash').and_return(mock_stage_class)

      expect { TransporterTool.new(*files, config, 'customer') }.to raise_error(TransporterTool::StageNotFoundError)
    end

    it 'passes specified params to the pipeline stage' do
      files = ['spec/files/blank.csv']
      config = 'spec/files/config-with-stage-parameters.yml'
      expected_pipeline_params = {
        'metafield_namespace' => 'migrations',
        'metafields' => %w(website group)
      }

      stage_with_params = double('stage_with_params')

      allow(Object).to receive(:const_get).with('ShopifyTransporter::Shopify::Customer')
      expect(Object).to receive(:const_get).once.with('CustomPipeline::Customer::PipelineWithParams').and_return(stage_with_params)

      expect { TransporterTool.new(*files, config, 'customer') }.to raise_error(TransporterTool::StageNotFoundError)
    end
  end

  context '#run' do
    context 'with valid empty csv entries' do
      it 'can call run and output just the headers to stdout' do
        files = ['spec/files/blank.csv']
        config = 'spec/files/config.yml'
        tool = TransporterTool.new(*files, config, 'customer')
        expect { tool }.not_to output("File spec/files/something.csv can't be found\n").to_stdout
        expect { tool.run }.to output(ShopifyTransporter::Shopify::Customer.header).to_stdout
      end
    end

    context 'record_key is required and missing (RequiredKeyMissing exceptions)' do
      before :each do
        file = tmpfile(firstname: 'john', lastname: 'doe')
        config = 'spec/files/config.yml'
        @tool = TransporterTool.new(*[file.path], config, 'customer')
      end

      it 'rescues ShopifyTransporter::RequiredKeyMissing exceptions' do
        expect { @tool.run }.not_to raise_error
      end

      it 'prints a message to stderr when a record key column does not exist in the input' do
        stderr = capture(:stderr) { @tool.run }
        expect(stderr).to match(/Required field not found/)
      end
    end

    context 'record_key is not required and missing (MissingParentObject exceptions)' do
      before :each do
        file = tmpfile(firstname: 'john', lastname: 'doe')
        config = 'spec/files/config-without-key-required.yml'
        @tool = TransporterTool.new(*[file.path], config, 'customer')
      end

      it 'rescues ShopifyTransporter::MissingParentObject exceptions' do
        expect { @tool.run }.not_to raise_error
      end

      it 'prints a message to stderr when a record key column is nil in the input row and there is no row above it' do
        stderr = capture(:stderr) { @tool.run }
        expect(stderr).to match(/Required field not found/)
      end

      it 'prints a message to stderr when a record key column is nil in the input row and on rows above it' do
        file = tmpfile([
          {
            firstname: 'john', lastname: 'doe'
          },{
            firstname: 'john', lastname: 'doe2'
          }
        ]);
        config = 'spec/files/config-without-key-required.yml'
        tool = TransporterTool.new(*[file.path], config, 'customer')
        stderr = capture(:stderr) { tool.run }
        expected_message = "cannot process entry. Required field not found: 'Email Address'"
        errors = stderr.split($/)
        expect(errors[0]).to match(/1, .*field not found/)
        expect(errors[1]).to match(/2, .*field not found/)
      end
    end

    it 'prints valid rows to stdout when other rows have errors' do
      file = tmpfile([
        {
          firstname: 'john', lastname: 'doe'
        },{
          email: 'jane.doe@shopify.com', firstname: 'jane', lastname: 'doe'
        }
      ]);
      config = 'spec/files/config.yml'
      tool = TransporterTool.new(*[file.path], config, 'customer')
      stderr = nil
      stdout = capture(:stdout) do
        stderr = capture(:stderr) { tool.run }
      end
      errors = stderr.split($/)
      expect(errors[0]).to match(/1, .*field not found/)
      expect(stdout.strip.split($/).count).to be > 1
    end

    it "will output an error if the file extension is neither 'csv' nor 'json'" do
      file = Tempfile.new(['test', '.pdf'])
      file.close
      tool = TransporterTool.new(*[file.path], '', 'customer')
      stderr = capture(:stderr) { tool.run }
      expect(stderr).to match(/File type must be one of: .csv, .json/)
    end

    it 'ignores case of extension' do
      file = Tempfile.new(['test', '.JsOn'])
      file.close
      config = 'spec/files/config.yml'
      tool = TransporterTool.new(*[file.path], config, 'customer')
      stderr = capture(:stderr) { tool.run }
      expect(stderr).not_to match(/File type must be one of: .csv, .json/)
    end

    it 'accepts a json file and goes through the pipeline stages and outputs a Shopify csv file' do
      file = tmpfile([
        { "firstname": "john", "lastname": "doe", "email": "john.doe@shopify.com" },
        { "firstname": "jane", "lastname": "doe", "email": "jane.doe@shopify.com" }
      ])
      config = 'spec/files/config.yml'
      tool = TransporterTool.new(*[file.path], config, 'customer')
      stdout = capture(:stdout) { tool.run }
      expect(stdout).to eq(
        "First Name,Last Name,Email,Phone,Accepts Marketing,Tags,Note,Tax Exempt,"\
        "Company,Address1,Address2,City,Province,Province Code,Zip,Country,"\
        "Country Code,Metafield Namespace,Metafield Key,Metafield Value,"\
        "Metafield Value Type\njohn,doe,john.doe@shopify.com,,,,,,,,,,,,,,,,,,\n"\
        "jane,doe,jane.doe@shopify.com,,,,,,,,,,,,,,,,,,\n"
      )
    end

    it 'sends the json data to the appropriate pipeline stages' do
      content = [
        { "firstname": "john", "lastname": "doe", "email": "john.doe@shopify.com" }
      ]
      pipeline_param = { "firstname"=>"john", "lastname"=>"doe", "email"=>"john.doe@shopify.com" }
      file = tmpfile(content)
      config = 'spec/files/config.yml'
      tool = TransporterTool.new(*[file.path], config, 'customer')
      expect_any_instance_of(
        ShopifyTransporter::Pipeline::Magento::Customer::TopLevelAttributes
      ).to receive(:convert).with(pipeline_param, {}).once
      tool.run
    end

    it 'prints valid json records to stdout when other records have errors' do
      content = [
        { "firstname": "john", "lastname": "doe", "email": "john.doe@shopify.com" },
        { "firstname": "jane", "lastname": "doe" }
      ]
      file = tmpfile(content)
      config = 'spec/files/config.yml'
      tool = TransporterTool.new(*[file.path], config, 'customer')
      stderr = nil
      stdout = capture(:stdout) do
        stderr = capture(:stderr) { tool.run }
      end
      errors = stderr.split($/)
      expect(errors[0]).to match(/2, .*field not found/)
      expect(stdout.split($/).count).to be > 1
    end
  end

  describe ShopifyTransporter::New do
    context 'help' do
      it 'the help to stdout' do
        expect(ShopifyTransporter::New).to receive(:help)
        content = capture(:stdout) do
          ShopifyTransporter::New.start(%w(-h))
        end
      end

      it 'prints a message if required options are not passed' do
        error = nil
        error = capture(:stderr) do
          ShopifyTransporter::New.start(%w(--invoked e))
        end
        expect(error).to match("No value provided for required options '--platform'")
      end
    end

    it 'lets the user know the acceptable platform names when not given' do
      in_temp_folder do
        error = nil
        capture(:stdout) do
          error = capture(:stderr) do
            ShopifyTransporter::New.start(%w(temp_project --platform=not_real))
          end
        end
        expect(error.strip).to eq("Expected '--platform' to be one of magento; got not_real")
        expect(File).to_not exist('temp_project/config.yml')
        expect(File).to_not exist('temp_project/lib/custom_pipeline_stages')
      end
    end

    context 'folder generation' do
      it 'generates a new project folder given a name and platform' do
        in_temp_folder do
          capture(:stdout) do
            ShopifyTransporter::New.start(%w(temp_project --platform=magento))
          end
          expect(File).to exist('temp_project/config.yml')
          expect(File).to exist('temp_project/lib/custom_pipeline_stages')
        end
      end
    end
  end

  describe ShopifyTransporter::Generate do
    context 'custom stage file generation' do
      it 'generates a custom stage for the class provided to the command' do
        in_temp_folder do
          capture(:stdout) do
            ShopifyTransporter::New.start(%w(temp_project --platform=magento))
            Dir.chdir('temp_project') do
              ShopifyTransporter::Generate.start(%w(CustomStage -O customer))
            end
          end
          expect(File).to exist('temp_project/lib/custom_pipeline_stages/custom_stage.rb')
        end
      end

      it 'outputs a warning to indicate that the config.yml is not present at root when the generated project is not the current working directory' do
        in_temp_folder do
          capture(:stdout) do
            ShopifyTransporter::New.start(%w(temp_project --platform=magento))
          end
          stdout = capture(:stdout) do
            expect { ShopifyTransporter::Generate.start(%w(CustomStage -O customer)) }.to raise_error(SystemExit)
          end
          expect(stdout.strip).to eq(
            "Cannot find config.yml at project root"
          )
          expect(File).to_not exist('temp_project/lib/custom_pipeline_stages/custom_stage.rb')
        end
      end

      it 'outputs that the config.yml already contains the custom stage when a user runs the same command twice' do
        in_temp_folder do
          capture(:stdout) do
            ShopifyTransporter::New.start(%w(temp_project --platform=magento))
          end
          Dir.chdir('temp_project') do
            capture(:stdout) do
              ShopifyTransporter::Generate.start(%w(CustomStage -O customer))
            end
            stdout = capture(:stdout) do
              ShopifyTransporter::Generate.start(%w(CustomStage -O customer))
            end
            expect(stdout.strip).to eq(
              "identical  lib/custom_pipeline_stages/custom_stage.rb\n"\
              "Warning: The pipeline stage CustomStage already exists in the config.yml"
              )
          end
        end
      end
    end
  end
end
