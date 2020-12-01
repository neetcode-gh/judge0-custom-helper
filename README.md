# Judge0
> Edgar's extended version of Judge0.

This Docker image contains additional libraries alongside the official Judge0 image.
### How do I use this?
Follow [official deployment procedure](https://github.com/judge0/judge0/blob/master/CHANGELOG.md#deployment-procedure) and after extracting Judge0 ZIP archive edit `docker-compose.yml` and change Docker image from `judge0/judge:X.Y.Z` to `registry.gitlab.com/edgar-group/judge0:X.Y.Z`.

After this edit, follow the rest of the procedure.

### How do I update?
After the new Judge0 release you should change the base image (`FROM`) of this Dockerfile.

Next, you need to build your new image:
```
docker build -t registry.gitlab.com/edgar-group/judge0:X.Y.Z
```

Finally, you need to push this newly created image to GitLab Registry:
```
docker push registry.gitlab.com/edgar-group/judge0:X.Y.Z
```

---

Please note that in order for `docker push` to work you need to login to GitLab's Registry since not everyone are allowed to write to your repository registry. To do that you need to:
```
docker login registry.gitlab.com
```

Enter your GitLab username and password on prompt.