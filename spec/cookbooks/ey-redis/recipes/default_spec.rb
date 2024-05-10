require 'chefspec'

describe 'ey-redis::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'includes the install recipe' do
    expect(chef_run).to include_recipe('ey-redis::install')
  end

  it 'includes the configure recipe' do
    expect(chef_run).to include_recipe('ey-redis::configure')
  end
end