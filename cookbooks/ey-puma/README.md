## Puma

Puma is a simple, fast, and highly concurrent HTTP 1.1 server for Ruby web applications. It is designed to be used with Rack, a Ruby webserver interface. Puma is a "hybrid" web server that allows both multi-threading and forking worker processes to handle requests and balance the load.

## Overview
This cookbook is used for the Puma server configuration. 

In v7, Puma has been divided into Puma Legacy and Puma. Puma Legacy is designed for versions of Puma prior to 5.1. Although v7 supports both Puma and Puma-legacy, Puma is the recommended version for new deployments.

Puma-legacy uses Monit to manage its service. Puma uses Systemd rather than Monit.

## Usage and Dependencies

This cookbook is one of the default cookbooks so you don't have to do anything specific for this cookbook to run. However for Puma to work properly in v7 there are some things to be aware of.

1. Your rails application must have **Puma 5.1** or higher in your gems.
2. You should also have **sd_notify** in your gems as it is required for Puma to work properly with Systemd.

## Notes

In the ey-puma/templates/app_control.erb file you can check some of the command you can use with the puma service created for your application.

## Additional Resources

For detailed information about engineyard and puma please refer to the articles in the support section.

[1]: [The Rails Application Server in Engine Yard(Puma-Passenger-Unicor)](https://support.engineyard.com/hc/en-us/articles/13764920373266-The-Rails-Application-Server-in-Engine-Yard#h_01HAEN737ZHFNRF2M9P9STPKXW)

[2]:[Release Notes including Puma changes](https://support.engineyard.com/hc/en-us/articles/7598153250578-Engine-Yard-Release-Notes-for-August-3rd-and-August-8th-2022-Stack-stable-v7-1-0-7)

[3]: [Comparison of App Servers](https://support.engineyard.com/hc/en-us/articles/8853168991250-Unicorn-vs-Puma-vs-Passenger-Comparison-of-each-App-Server)

