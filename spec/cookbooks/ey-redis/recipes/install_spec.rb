require 'chefspec'

describe 'ey-redis::install' do
  context 'when redis is installed from source' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['redis']['install_from_source'] = true
      end.converge(described_recipe)
    end

    it 'includes the install_from_source recipe' do
      expect(chef_run).to include_recipe('ey-redis::install_from_source')
    end
  end

  context 'when redis is installed from package' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['redis']['install_from_source'] = false
      end.converge(described_recipe)
    end

    it 'includes the install_from_package recipe' do
      expect(chef_run).to include_recipe('ey-redis::install_from_package')
    end
  end

  context 'when redis version is invalid' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['redis']['version'] = 'invalid'
      end.converge(described_recipe)
    end

    it 'logs a fatal error' do
      expect { chef_run }.to raise_error(SystemExit)
    end
  end

  context 'when redis version is valid' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['redis']['version'] = '4.0.9'
      end.converge(described_recipe)
    end

    it 'does not log a fatal error' do
      expect { chef_run }.not_to raise_error
    end
  end

  context 'when node is a redis instance' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          node.normal['redis']['is_redis_instance'] = true
        end.converge(described_recipe)
      end
  
      it 'sets vm.overcommit_memory to 1' do
        expect(chef_run).to set_sysctl('vm.overcommit_memory').with(value: 1)
      end
  
      it 'disables transparent huge pages when present' do
        expect(chef_run).to run_execute('disable transparent huge pages when present')
      end
  
      it 'sets transparent huge pages on boot' do
        expect(chef_run).to run_execute('set /sys/kernel/mm/transparent_hugepage/enabled on boot')
      end
    end
  
    context 'when node is not a redis instance' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          node.normal['redis']['is_redis_instance'] = false
        end.converge(described_recipe)
      end
  
      it 'does not set vm.overcommit_memory' do
        expect(chef_run).not_to set_sysctl('vm.overcommit_memory')
      end
  
      it 'does not disable transparent huge pages' do
        expect(chef_run).not_to run_execute('disable transparent huge pages when present')
      end
  
      it 'does not set transparent huge pages on boot' do
        expect(chef_run).not_to run_execute('set /sys/kernel/mm/transparent_hugepage/enabled on boot')
      end
    end
  
    context 'when node is a redis slave' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          node.normal['dna']['instance_role'] = 'app_master'
          node.normal['redis']['slave_name'] = 'slave'
          node.normal['dna']['name'] = 'slave'
          node.normal['redis']['utility_name'] = 'master'
          node.normal['dna']['engineyard']['environment']['instances'] = [
            { 'name' => 'master', 'private_hostname' => 'master.private' }
          ]
        end.converge(described_recipe)
      end
  
      it 'sets master_ip in redis_config_variables' do
        expect(chef_run.node['redis']['master_ip']).to eq('master.private')
      end
    end
  
  # ... rest of your tests ...
end