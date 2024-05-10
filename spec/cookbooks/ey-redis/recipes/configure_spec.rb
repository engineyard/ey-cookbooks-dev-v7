require 'chefspec'

describe 'ey-redis::configure' do
  context 'when instance role is not a database' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['dna']['instance_role'] = 'app_master'
        node.normal['dna']['engineyard']['environment']['instances'] = [
          { 'name' => 'redis', 'private_hostname' => 'redis.private' }
        ]
        node.normal['redis']['utility_name'] = 'redis'
        node.normal['dna']['applications'] = { 'myapp' => {} }
        node.normal['owner_name'] = 'deploy'
        node.normal['dna']['engineyard']['environment']['framework_env'] = 'production'
      end.converge(described_recipe)
    end

    it 'removes existing redis-instance mapping from /etc/hosts' do
      expect(chef_run).to run_execute('Remove existing redis-instance mapping from /etc/hosts')
    end

    it 'adds redis-instance mapping to /etc/hosts' do
      expect(chef_run).to run_execute('Add redis-instance mapping to /etc/hosts')
    end

    it 'creates redis.yml for each application' do
      expect(chef_run).to create_template('/data/myapp/shared/config/redis.yml').with(
        source: 'redis.yml.erb',
        owner: 'deploy',
        group: 'deploy',
        mode: '0655',
        variables: {
          environment: 'production',
          hostname: 'redis.private'
        }
      )
    end
  end

  context 'when instance role is a database' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['dna']['instance_role'] = 'db_master'
      end.converge(described_recipe)
    end

    it 'does not remove existing redis-instance mapping from /etc/hosts' do
      expect(chef_run).not_to run_execute('Remove existing redis-instance mapping from /etc/hosts')
    end

    it 'does not add redis-instance mapping to /etc/hosts' do
      expect(chef_run).not_to run_execute('Add redis-instance mapping to /etc/hosts')
    end

    it 'does not create redis.yml for each application' do
      expect(chef_run).not_to create_template('/data/myapp/shared/config/redis.yml')
    end
  end
end