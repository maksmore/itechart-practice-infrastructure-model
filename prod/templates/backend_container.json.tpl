[
    {      
      "name" : "prod_backend",
      "image" : "${backend_image}",
      "entryPoint" : [],
      "command" : [],
      "environment": [
        {
          "name": "APPLE_CALLBACK_URL",
          "value": "123456789"
        },
        {
          "name": "APPLE_CLIENT_ID",
          "value": "123456789"
        },
        {
          "name": "APPLE_KEY_ID",
          "value": "123456789"
        },
        {
          "name": "APPLE_SERVICE_ID",
          "value": "123456789"
        },
        {
          "name": "APPLE_TEAM_ID",
          "value": "123456789"
        },
        {
          "name": "DB_HOST",
          "value": "${db_host}"
        },
        {
          "name": "DB_PORT",
          "value": "5432"
        },
        {
          "name": "DB_PASSWORD",
          "value": "postgres"
        },
        {
          "name": "FRONTEND_URL",
          "value": "https://${domain_name}"
        },
        {
          "name": "GOOGLE_CLIENT_ID",
          "value": "123456789"
        },
        {
          "name": "GOOGLE_CLIENT_SECRET",
          "value": "111"
        },
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        },
        {
          "name": "ECS_AVAILABLE_LOGGING_DRIVERS",
          "value": "awslogs"
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
          "containerPort" : 3000,
          "hostPort" : 0
        }
      ],
      "cpu" : 2048,
      "memory" : 2048,
      "networkMode" : "bridge"
    }
  ]