# Interview Questions and Answers (Task 3: IaC with Terraform)

## 1. What is IaC?
**Infrastructure as Code** means that servers, networks, containers and other infrastructure are described in code
files and created by a tool, instead of being created by hand in a console. The code is stored in Git, reviewed,
tested and re-used like application code. Benefits: repeatable and consistent environments, fewer manual mistakes,
history and rollback through version control, and fast creation of identical environments.
Examples of IaC tools: Terraform, OpenTofu, CloudFormation, Pulumi, Ansible.

## 2. How does Terraform work?
Terraform is a **declarative** tool: you describe the **desired end state** in HCL files (`*.tf`), and Terraform works
out how to reach it.
1. **Write** the configuration (providers, resources, variables).
2. **`terraform init`** downloads the required providers and prepares the working directory.
3. **`terraform plan`** reads the configuration, the **state** and the real infrastructure, builds a
   **dependency graph** and shows what will be created, changed or destroyed.
4. **`terraform apply`** executes the plan through the provider APIs (here the Docker API) and records the result in the state.
5. **`terraform destroy`** removes everything that Terraform manages.

## 3. What is the Terraform state file?
`terraform.tfstate` is a JSON file in which Terraform stores **what it has created**: it maps each resource in the code
to the real object (for example the container ID) and keeps its attributes. Terraform compares the code, the state and
reality to decide what must change. Important points:
- It can contain **secrets in plain text**, so never commit it to Git.
- Teams store it in a **remote backend** (encrypted storage with locking) so that everyone shares the same state and
  two people cannot apply at the same time.
- Never edit it by hand; use commands such as `terraform state list`, `terraform state show <resource>`,
  `terraform state mv` and `terraform state rm`.

## 4. Difference between apply and plan
`terraform plan` is a **dry run**: it only shows what Terraform would create, change or destroy and changes nothing.
`terraform apply` **performs** the changes (after asking for confirmation, or with `-auto-approve`).
Best practice: run `plan` first and review it; in automation save it with `plan -out=tfplan` and apply exactly that file
with `apply tfplan`, so what was reviewed is what runs.

## 5. What are Terraform providers?
Providers are **plugins** that let Terraform talk to an API: cloud platforms (AWS, Azure, Google Cloud), Docker,
Kubernetes, GitHub and many more. A provider defines the resource types (for example `docker_container`) and the
data sources. They are declared in `required_providers` with a source and a version, downloaded by `terraform init`
from the Terraform Registry, and the exact versions are recorded in `.terraform.lock.hcl`.
This project uses `kreuzwerker/docker` and `hashicorp/local`.

## 6. What is resource dependency?
It is the order in which resources must be created. Terraform builds a graph and handles it automatically:
- **Implicit dependency:** a resource refers to another one, for example `image = docker_image.nginx.image_id`.
  Terraform creates the image first.
- **Explicit dependency:** `depends_on = [...]` when there is no reference but the order still matters.
Independent resources are created **in parallel**; destroy runs in the **reverse order**
(container first, then network). `terraform graph` prints the dependency graph.

## 7. How do you handle secret variables?
- Declare them with `sensitive = true` so that Terraform hides them in plans and outputs.
- Do not hard-code secrets or commit `*.tfvars` files with real values; pass them with environment variables
  (`TF_VAR_name`), a git-ignored `terraform.tfvars`, or the CI/CD secret store.
- Read them from a secret manager (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, Google Secret Manager).
- Remember that the **state file still contains the values in plain text**: use an encrypted remote backend with
  restricted access, and never commit the state.

## 8. Explain the benefits of Terraform
- **Declarative and readable:** you describe what you want, not the steps.
- **Multi-cloud and multi-provider:** one tool and one language for AWS, Azure, Google Cloud, Docker, Kubernetes and more.
- **Plan before apply:** you preview every change and avoid surprises.
- **Version control and collaboration:** infrastructure is reviewed and tracked like code; remote state with locking for teams.
- **Idempotent and consistent:** applying twice gives the same result (the second plan says "No changes").
- **Dependency handling and parallelism:** correct order and faster runs.
- **Reusable modules and variables:** the same code for dev, staging and prod.
- **Automation and cost control:** easy to create and destroy whole environments, and to run in CI/CD.
