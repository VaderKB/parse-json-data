# Base Image
FROM public.ecr.aws/lambda/python:3.9


COPY generate_data.py ${LAMBDA_TASK_ROOT}

COPY requirements.txt .

RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["generate_data.lambda_handler"]