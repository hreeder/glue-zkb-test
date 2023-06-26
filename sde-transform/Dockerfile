FROM public.ecr.aws/lambda/python:3.10

RUN yum install -y libyaml-devel && \
    yum -y clean all && \
    rm -rf /var/cache

COPY requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install -r requirements.txt

COPY lambda_function.py ${LAMBDA_TASK_ROOT}

CMD [ "lambda_function.handler" ]