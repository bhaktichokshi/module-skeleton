#!/bin/bash

# Snippet Author: Bhakti Chokshi (chokshibhakti13@gmail.com)
# Snippet Maintainer: Bhakti Chokshi

# Function to write module details in Python files
add_module_details() {
  content="__author__ = \"$maintainer_name\"\n__credits__ = \"$maintainer_name\"\n__maintainer__ = \"$maintainer_email\"\n__version__ = \"0.0.0\"\n__status__ = \"Development\"\n__module_name__ = \"$module_name\""

  for file in "$target_directory/_setup.py"; do
    if [ -f "$file" ]; then
      echo -e "$content" > "$file"
    fi
  done
}

# Function to add content in entrypoint.sh
configure_entrypoint() {
  if [[ $project_type == "API" ]]; then
    content=$(cat << EOF
#!/bin/bash
export PATH="/home/ubuntu/miniconda/bin:\$PATH"

source activate $module_name

uvicorn main:app \$@
EOF
)
  elif [[ $project_type == "ECS + Lambda" || $project_type == "ECS" ]]; then
    content=$(cat << EOF
#!/bin/bash
export PATH="/home/ubuntu/miniconda/bin:\$PATH"

source activate $module_name

python main.py \$@
EOF
)
  elif [[ $project_type == "ECS + API" || $project_type == "ECS + API + Lambda" ]]; then
    content=$(cat << EOF
#!/bin/bash
export PATH="/home/ubuntu/miniconda/bin:\$PATH"

source activate $module_name

if [[ "\${RUN_MODE}" == "ECS" ]]; then
  python ecs_main.py \$@
else
  uvicorn main:app \$@
fi
EOF
)
  elif [[ $project_type == "Streamlit" ]]; then
    content=$(cat << EOF
#!/bin/bash

export PATH="/home/ubuntu/miniconda/bin:\$PATH"

source activate $module_name

ddtrace-run streamlit run streamlit_main.py $@
EOF
)
  else
    return
  fi

  echo -e "$content" > "$target_directory/bin/entrypoint.sh"
}

# Add files in bumpversion.cfg
configure_bumpversion() {
  content="[bumpversion]
current_version = 0.0.0
commit = True
tag = False

[bumpversion:file:./VERSION]

[bumpversion:file:./README.md]

[bumpversion:file:./_setup.py]
"

  echo -e "$content" > "$target_directory/.bumpversion.cfg"
}

# Add dependencies in environment.yml
configure_environment_file() {
  content=$(cat << EOF
name: $module_name
channels:
  - defaults
dependencies:
  - python=3.9.5
  - pip:
      -
prefix: ./venv/$module_name
EOF
)

  echo -e "$content" > "$target_directory/environment.yml"
}

# Add basic details in README.md
configure_readme_file() {
  content=$(cat << EOF
# $module_name
EOF
)
  echo -e "$content" > "$target_directory/README.md"
}

# Add sections in config
configure_config_file() {
  content=$(cat << EOF
[DEFAULT]

[prod]

[preprod]

[stage]

[test]
EOF
)
   echo -e "$content" > "$target_directory/config/app.config"
}

# Add environment variables
configure_env_file() {
  content=$(cat << EOF
export CONFIG='config/app.config'
export ENV_MODE='stage'
EOF)
  echo -e "$content" > "$target_directory/env.sh"
}

# Function to create ECS project structure
create_ecs_structure() {
  mkdir -p "$target_directory/bin"
  mkdir -p "$target_directory/config"
  mkdir -p "$target_directory/$module_name/utils"
  mkdir -p "$target_directory/query"
  mkdir -p "$target_directory/tests"

  touch "$target_directory/.bumpversion.cfg" "$target_directory/env.sh" "$target_directory/environment.yml" "$target_directory/README.md" "$target_directory/VERSION"
  touch "$target_directory/bin/entrypoint.sh"
  touch "$target_directory/config/app.config"
  touch "$target_directory/$module_name/utils/common.py"
  touch "$target_directory/$module_name/core.py"
  touch "$target_directory/$module_name/handler.py"
  touch "$target_directory/query/sample.sql"
  touch "$target_directory/tests/test_main.py"
  touch "$target_directory/_setup.py"

  # Convert prefix to lowercase using tr
  if [[ $prefix == "both" ]]; then
    touch "$target_directory/api_main.py"
    touch "$target_directory/ecs_main.py"
  elif [ -n "$prefix" ]; then
    project_main_file=$(echo "${prefix}_main.py" | tr '[:upper:]' '[:lower:]')
    touch "$target_directory/$project_main_file"
  else
    project_main_file="main.py"
    touch "$target_directory/$project_main_file"
  fi

  # Add module details
  add_module_details

  # Configure entrypoint.sh
  configure_entrypoint

  # Configure .bumpversion.cfg
  configure_bumpversion

  # Configure environment.yml
  configure_environment_file

  # Add readme details
  configure_readme_file

  # Add sections in config
  configure_config_file

  # Add env variables
  configure_env_file

  # Add version
  echo -e "0.0.0" > "$target_directory/VERSION"

  echo "Skeleton created successfully in $target_directory."
}

# Function to create Lambda project structure
create_lambda_structure() {
  mkdir -p "$target_directory/config"
  mkdir -p "$target_directory/utils"

  touch "$target_directory/lambda_function.py" "$target_directory/requirements.txt"
  touch "$target_directory/config/app.config"
  touch "$target_directory/utils/common.py"
  touch "$target_directory/utils/core.py"
  touch "$target_directory/README.md"
  touch "$target_directory/_setup.py"

  # Add module details
  add_module_details

  # Add readme details
  configure_readme_file

  # Add sections in config
  configure_config_file

  echo "Skeleton created successfully in $target_directory."
}

# Function to display project type options and get user input
select_project_type() {
  echo "Select Project Type:"
  echo "1) Lambda"
  echo "2) API"
  echo "3) ECS"
  echo "4) ECS + Lambda"
  echo "5) ECS + API"
  echo "6) ECS + API + Lambda"
  echo "7) Streamlit"
  read -p "Enter the number corresponding to the project type: " project_type_choice

  case $project_type_choice in
    1) project_type="Lambda" ;;
    2) project_type="API" ;;
    3) project_type="ECS" ;;
    4) project_type="ECS + Lambda" ;;
    5) project_type="ECS + API" ;;
    6) project_type="ECS + API + Lambda" ;;
    7) project_type="Streamlit" ;;
    *) echo "Invalid choice. Please enter a valid number." ; select_project_type ;;
  esac
}

select_project_type
read -p "Enter Target Directory: " target_directory
read -p "Enter Module Name: " module_name
read -p "Enter Maintainer's name: " maintainer_name
read -p "Enter Maintainer's email: " maintainer_email

# Set the target directory to current directory if not provided
target_directory=${target_directory:-.}

# Create the appropriate structure based on the project type
if [[ $project_type == "Lambda" ]]; then
  create_lambda_structure $target_directory
elif [[ $project_type == "API" || $project_type == "ECS" ]]; then
  prefix=""
  create_ecs_structure $target_directory
elif [[ $project_type == "ECS + API" ]]; then
  prefix="both"
  create_ecs_structure $target_directory
elif [[ $project_type == "ECS + Lambda" ]]; then
  # Make ECS skeleton
  prefix="ECS"
  create_ecs_structure $target_directory

  # Make Lambda skeleton
  target_directory="$target_directory/lambda"
  mkdir -p "$target_directory"
  create_lambda_structure "$target_directory"
elif [[ $project_type == "ECS + API + Lambda" ]]; then
  # Make ECS + API
  prefix="both"
  create_ecs_structure $target_directory

  # Make Lambda skeleton
  target_directory="$target_directory/lambda"
  mkdir -p "$target_directory"
  create_lambda_structure "$target_directory"
elif [[ $project_type == "Streamlit" ]]; then
  # Make ECS
  prefix="Streamlit"
  create_ecs_structure $target_directory
else
  echo "Invalid project type. Please provide from the following values: ECS, Lambda, ECS + Lambda, API."
  exit 1
fi