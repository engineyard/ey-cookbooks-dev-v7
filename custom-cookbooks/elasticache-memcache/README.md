## Optional Cookbook for Engine Yard Cloud

# Elasticache Memcache

AWS Elasticache is managed service for Memcache.

## Overview

This cookbook generates configuration file from provided environment variables.

## Installation

### Environment Variables

When the environment variable `EY_ELASTICACHE_MEMCACHE_ENABLED` is set to "true", this recipe will be enabled and setup up Memcache configuration file.
`EY_ELASTICACHE_MEMCACHE_URL` vairable will be used for the URL


### Custom Chef

Since this is an optional recipe, it can be installed by simply including it via a `depends` in your `ey-custom/metadata.rb` file and an `include_recipe` in the appropriate hook file.

## Notes

1. This recipe will put in place a `memcached.yml` on `/data/{app_name}/shared/config/`.
