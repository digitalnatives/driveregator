# Driveregator

A little ruby gem to help you review your GoogleDrive permissions.

## Usage

    require 'driveregator'

    # Get your credentials from the APIs Console
    # create project here: https://code.google.com/apis/console/
    # drive api - Courtesy limit: 10,000,000 requests/day

    # this will ask for access_key via browser
    reporter = Driveregator::PermissionReporter.new("YOUR_GOOGLE_APP_KEY", "YOUR_GOOGLE_APP_SECRET")

    reporter.report_by_users # creates a yaml file with the permissions grouped by users

    reporter.report_by_files # creates a yaml file with the permissions grouped by files