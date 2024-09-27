### Use case : 

- Use this script if you want to list out the AWS health event codes, event codes for specific cateogry or service. 


## How to use

#### Considerations

> [!IMPORTANT]
> 
> + The script is tested on the following Operting Systems :
>
>    > ```
>    > - Linux
>    > - MacOS
>    > ``` 

#### Prerequisites

> [!WARNING]
> 
>
> 1. Please make sure that `wget` package installed. 
> 2. Please make sure that AWS CLI is [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

#### Download the script 

```sh 
wget https://raw.githubusercontent.com/sattyagrah/AWSHealthCLI/refs/heads/main/aws_health.sh
```

#### Give executable permission

```sh
chmod u+x aws_health.sh
```

#### Execute the script

```sh
./aws_health.sh
```