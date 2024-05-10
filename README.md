# Engine Yard Cloud v7 Chef Recipes

- This codebase and its cookbooks represent the latest version of Engine Yard's **`stable-v7-1.0`** stack.

## Dependencies

To upload and run the recipes from the CLI, you need the `ey-core` gem.

```
gem install ey-core
```

## Usage

### Environment Variables Settings

Many features in an Engine Yard Cloud stable-v7 environment can now be enabled
and configured via [environment variables](https://support.cloud.engineyard.com/hc/en-us/articles/360007661794).

This makes working with the Engine Yard Cloud platform much easier and 
removes the need for custom Chef recipes in many cases.

More details can be found [here](./EnvironmentVariables.md).

### Custom Chef

1. Create the `cookbooks/` directory at the root of your application. If you prefer to keep the infrastructure code separate from application code, you can create a new repository.
2. For each custom cookbook that you want to use, do the following:
	- Create or edit `cookbooks/ey-custom/recipes/after-main.rb` and add the line:

	 ```
	 include_recipe 'custom-<recipe>'
	 ```
	- Create or edit `cookbooks/ey-custom/metadata.rb` and add the line `depends 'custom-<recipe>'`
		- prepend `name 'ey-custom'` to `cookbooks/ey-custom/metadata.rb` in case of a creation
	- Download this repository and copy `custom-cookbooks/<recipe>/cookbooks/custom-<recipe>` to `cookbooks`. For example, to use memcached, copy `custom-cookbooks/memcached/cookbooks/custom-memcached ` to `cookbooks/custom-memcached`.

3. To upload and apply the recipes, run

	```
	ey-core recipes upload --environment <nameofenvironment> --apply
	```

For more information about our V7 (20.04 LTS) Stack, please see https://www.engineyard.com/blog/engine-yard-stack-v7-is-now-generally-available/

## Contributing/Development

Please read our [Contributions Guidelines](https://github.com/engineyard/ey-cookbooks-stable-v7/blob/next-release/CONTRIBUTING.md).

## Test suite

The provide unit test suite is a work in progress. It relies on ChefSpec and Docker.

1. Build the Docker image: Run the following command in the directory containing the Dockerfile. This will create a Docker image named my-chefspec-tests.

```
docker build -t v7-chefspec-tests .
```

2. Run the tests: After the image is built, you can run the tests with the following command:
```
docker run v7-chefspec-tests
```
This command will start a Docker container from the v7-chefspec-tests image and execute the ChefSpec tests.