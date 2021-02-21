

## Customize nms:

```bash
pod=`kubectl get pod -l io.kompose.service=magmalte -o jsonpath='{.items[0].metadata.name}'` && echo $pod
kubectl exec -it $pod bash 
```

## Edit The file:

cd /usr/src/node_modules/@fbcnms/ui/components/auth

vi LoginForm.js

From:
<Text className={classes.title} variant="h5">
    {this.props.title}
</Text>

To:
{window.location.href.split(".")[0].replace("https://", "").toUpperCase() + " NMS"}



# And also the files: 
/usr/src/packages/magmalte/views/login.pug
/usr/src/packages/magmalte/views/master.pug
/usr/src/packages/magmalte/views/index.pug

From:
title Magma
to:
title NMS

