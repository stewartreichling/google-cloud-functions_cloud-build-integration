.PHONY: deploy

deploy:
	gcloud builds submit --config cloudbuild.yaml --substitutions=_PREFIX="myprefix" .

delete:
	gcloud builds submit --config cloudbuilddelete.yaml --substitutions=_PREFIX="myprefix" --no-source