 # frozen_string_literal: true

RSpec.describe TransporterExporter do
  context '#run' do
    it 'raises NotImplementedError' do
      expect{subject.new.run}.to raise_error(NotImplementedError)
    end
  end
end
