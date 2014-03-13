require 'spec_helper'

describe Berkshelf::Vagrant::Config do
  let(:unset_value) { described_class::UNSET_VALUE }
  let(:config) { described_class.new }

  it "sets a path to a Berksfile in the current working directory for berksfile_path" do
    subject.berksfile_path.should eql(File.join(Dir.pwd, "Berksfile"))
  end

  context "when the Berksfile exists" do
    before do
      File.should_receive(:exist?).with(File.join(Dir.pwd, "Berksfile")).and_return(true)
    end

    it "it sets the value of enabled to true" do
      config.enabled.should be true
    end
  end

  context "when the Berksfile doesn't exist" do
    before do
      File.should_receive(:exist?).with(File.join(Dir.pwd, "Berksfile")).and_return(false)
    end

    it "set the value of enabled to false" do
      config.enabled.should be false
    end
  end

  it "sets the value of only to an empty array" do
    subject.only.should be_a(Array)
    subject.only.should be_empty
  end

  it "sets the value of except to an empty array" do
    subject.except.should be_a(Array)
    subject.except.should be_empty
  end

  it "sets the value of node_name to the value in the Berkshelf::Config.instance" do
    subject.node_name.should eql(Berkshelf::Config.instance.chef.node_name)
  end

  it "sets the value of client_key to the value in Berkshelf::Config.instance" do
    subject.client_key.should eql(Berkshelf::Config.instance.chef.client_key)
  end

  describe "#validate" do
    let(:env) { double('env', root_path: Dir.pwd ) }
    let(:config) { double('config', berkshelf: subject) }
    let(:machine) { double('machine', config: config, env: env) }

    before do
      subject.finalize!
    end

    context "when the plugin is enabled" do
      before(:each) do
        subject.stub(enabled: true)
        env.stub_chain(:vagrantfile, :config, :vm, :provisioners, :any?)
      end

      let(:result) { subject.validate(machine) }

      it "returns a Hash with a 'berkshelf configuration' key" do
        result.should be_a(Hash)
        result.should have_key("berkshelf configuration")
      end

      context "when all validations pass" do
        before(:each) do
          File.should_receive(:exist?).with(subject.berksfile_path).and_return(true)
        end

        it "contains an empty Array for the 'berkshelf configuration' key" do
          result["berkshelf configuration"].should be_a(Array)
          result["berkshelf configuration"].should be_empty
        end
      end
    end

    context "when the plugin is disabled" do
      let(:machine) { double('machine', env: env) }

      before do
        subject.stub(enabled: false)
      end

      it "does not perform any validations" do
        machine.should_not_receive(:config)

        subject.validate(machine)
      end
    end
  end
end
