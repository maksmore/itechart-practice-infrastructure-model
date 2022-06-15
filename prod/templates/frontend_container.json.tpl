[
    {      
      "name" : "prod_frontend",
      "image" : "${frontend_image}",
      "entryPoint" : [],
      "command" : [],
      "environment": [
        {
          "name": "GENERATE_SOURCEMAP",
          "value": "false"
        },
        {
          "name": "REACT_APP_BACKEND_HOSTNAME",
          "value": "https://${backend_path}"
        },
        {
          "name": "REACT_APP_CONSUMER_KEY_TWITTER",
          "value": "5ApEbMv350YcTG2BV92tqMeKZ"
        },
        {
          "name": "REACT_APP_GOOGLE_CLIENT_ID",
          "value": "311142221504-i0l0vrh3oskug57k94fn51i4vdfn7jem.apps.googleusercontent.com"
        },
        {
          "name": "APPLE_TEAM_ID",
          "value": "123456789"
        },
        {
          "name": "REACT_APP_FACEBOOK_APP_ID",
          "value": "1656234954543556"
        },
        {
          "name": "ECS_AVAILABLE_LOGGING_DRIVERS",
          "value": "awslogs"
        },
        {
          "name": "PORT",
          "value": "3001"
        }
      ],
      "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${log_group_name}",
                "awslogs-region": "${log_group_region}"
            }
        },
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 3001,
          "hostPort" : 0
        }
      ],
      "cpu" : 2048,
      "memory" : 4096,
      "networkMode" : "bridge"
    }
  ]