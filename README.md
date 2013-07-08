# Driveregator

A little ruby gem to help you review your GoogleDrive permissions.

## Usage

    require 'driveregator'

    # Get your credentials from the APIs Console:
    # create project here: https://code.google.com/apis/console/
    # in the api access tab click "Create another client ID..."
    # then choose "installed application" and "other"
    # click "Create client ID" and then you have your creditentials

    # drive api - Courtesy limit: 10,000,000 requests/day

    # this will ask for creaditentials and access_key via browser
    # it saves the creds under ~/.driveregator for later use, so you only have to provide them once
    reporter = Driveregator::PermissionReporter.new

    reporter.report_by_users # creates a yaml file with the permissions grouped by users
    reporter.report_by_files # creates a yaml file with the permissions grouped by files

    # depending on the number of files you have in your drive, the reporting can take time (a minute or two)

    # also there are two executables you can use : driveregate_users and driveregate_files respectively