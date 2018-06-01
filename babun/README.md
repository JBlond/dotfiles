How to use the Windows' user profile directory as my home directory in babun ?

You need to add the environment variable HOME into your windows account.

    Edit your environment variables

        execute rundll32 sysdm.cpl,EditEnvironmentVariables or search in the start menu for env and select "Select Edit environment variables for your account"

        Select New

            Name: HOME

            Value: C:\Users\USERNAME

    Launch babun

    Type babun install

    Restart babun

Your babun home directory should now be your windows user profile directory, usually c:\user\USERNAME
