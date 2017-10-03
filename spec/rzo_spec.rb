require 'spec_helper'

RSpec.describe Rzo do
  it 'has a version number' do
    expect(Rzo::VERSION).not_to be nil
  end

  it 'responds to .version' do
    expect(described_class).to respond_to :version
  end

  it '.version == Rizzo::VERSION' do
    expect(described_class.version).to eq(Rzo::VERSION)
  end

  let(:argv) { [] }
  let(:rizzo_config) { '_home_rizzo.json' }
  let(:expected_output) { fixture('Vagrantfile.expected.1') }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  let :app do
    # Prevent trollop calling Kernel#exit()
    allow(Rzo::Trollop).to receive(:educate)
    myapp = Rzo::App.new(argv, ENV.to_hash, stdout, stderr)
    # Configuration file loaded from spec fixture
    example_config = JSON.parse(fixture(rizzo_config))
    allow(myapp).to receive(:load_rizzo_config).and_return(example_config)
    # The app instance under test
    myapp
  end

  describe 'rzo app with no options or arguments' do
    it 'educates the user (e.g. --help)' do
      expect(Rzo::Trollop).to receive(:educate)
      app.run
    end
  end

  describe 'generate' do
    let(:argv) { ['generate'] }
    describe 'output Vagrantfile' do
      # The actual Vagrantfile content written to disk
      subject do
        output_file = StringIO.new
        expect(app.subcommand_generate).to receive(:write_file).with('Vagrantfile').and_yield(output_file)
        expect(app.subcommand_generate).to receive(:timestamp).and_return('2017-08-18 13:00:09 -0700')
        allow(app.subcommand_generate).to receive(:validate_existence).and_return(nil)
        expect(Rzo).to receive(:version).and_return('0.1.0')
        app.run
        output_file.rewind
        output_file.read
      end

      it 'has no nodes' do
        expect(subject).to eq(fixture('Vagrantfile.expected.1'))
      end

      context 'with a full config file' do
        let(:rizzo_config) { '_complete_rizzo.json' }

        it 'has many nodes' do
          expect(subject).to eq(fixture('_complete_Vagrantfile.rb'))
        end
      end
    end
  end

  describe 'config' do
    let(:argv) { ['config'] }
    describe 'output' do
      let :output do
        output_file = StringIO.new
        expect(app.generate_subcommand).to receive(:write_file).with('STDOUT').and_yield(output_file)
        app.run
        output_file.rewind
        output_file.read
      end

      let :config do
        JSON.parse(output)
      end

      context 'when inside a control repo with .rizzo.json in the project root' do
        subject do
          config['control_repos']
        end

        fit 'moves the control repo to the top' do
          is_expected.to eq([])
        end
      end
    end
  end
end
