FROM python:3.12-slim AS build

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src
COPY tests ./tests

RUN pip install -U pip setuptools wheel \
 && pip install .[test]

CMD ["pytest"]
