import boto3
import botocore

from read_orders import main

def lambda_handler(event, context):
   main()
   print(f'boto3 version: {boto3.__version__}')
   print(f'botocore version: {botocore.__version__}')