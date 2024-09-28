### Use case : 

- Use this script if you want to test any script or user-data at once on some common linux distribution with different architectures. 


## How to use

#### Considerations

> [!IMPORTANT]
> 
> + The script is tested on the following Operting Systems :
>
>     ```
>     - Linux
>     - MacOS
>     ```

#### Prerequisites

> [!WARNING]
> 
> + Please make sure that AWS CLI is [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

#### Download the script 

```sh 
curl "https://raw.githubusercontent.com/sattyagrah/AWSHealthCLI/refs/heads/ignore/Ignore/check_script_at_once.sh" -o "aws_check_script_at_once.sh"
```

#### Give executable permission

```sh
chmod u+x aws_check_script_at_once.sh
```

#### Execute the script

```sh
./aws_check_script_at_once.sh
```

> [!NOTE]
> User can use `wget` also to download the script. 