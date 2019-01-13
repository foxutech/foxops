# Create an IAM role for the Web Servers.
resource "aws_iam_role" "web_iam_role" {
    name = "web_iam_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "web_instance_profile" {
    name = "web_instance_profile"
    roles = ["web_iam_role"]
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name = "web_iam_role_policy"
  role = "${aws_iam_role.web_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::bucket-name"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::bucket-name/*"]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "apps_bucket" {
    bucket = "bucket-name"
    acl = "private"
    versioning {
            enabled = true
    }
    tags {
        Name = "bucket-name"
    }
}

resource "aws_instance" "build" {
    ami = "ami-7de87d0e" # Windows_Server-2012-RTM-English-64Bit-Base-2016.05.11 (ami-7de87d0e)
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "ssh_key"
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    vpc_security_group_ids = [
      "${aws_security_group.web_access.id}",
      "${aws_security_group.rdp_access.id}"
     ]
    tags {
      Name = "build"
    }
    user_data = "${file("setup_scripts/buildserver/setup.ps1")}"
    iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"
}
