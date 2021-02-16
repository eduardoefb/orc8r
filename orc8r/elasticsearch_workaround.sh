#!/bin/bash

# Workaround when elasticsearch fails with error (to be changed to a configmap with the flag):
# {"type": "server", "timestamp": "2021-02-16T23:18:51,951+0000", "level": "WARN", "component": "o.e.b.ElasticsearchUncaughtExceptionHandler", "cluster.name": "docker-cluster", "node.name": "elasticsearch-7dc96b8684-ngp6n",  "message": "uncaught exception in thread [main]" , 
#"stacktrace": ["org.elasticsearch.bootstrap.StartupException: ElasticsearchException[Failure running machine learning native code. This could be due to running on an unsupported OS or distribution, missing OS libraries, or a problem with the temp directory. To bypass this problem by running Elasticsearch without machine learning functionality set [xpack.ml.enabled: false].]",
#"at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:163) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:150) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.cli.EnvironmentAwareCommand.execute(EnvironmentAwareCommand.java:86) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:124) ~[elasticsearch-cli-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.cli.Command.main(Command.java:90) ~[elasticsearch-cli-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:115) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:92) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"Caused by: org.elasticsearch.ElasticsearchException: Failure running machine learning native code. This could be due to running on an unsupported OS or distribution, missing OS libraries, or a problem with the temp directory. To bypass this problem by running Elasticsearch without machine learning functionality set [xpack.ml.enabled: false].",
#"at org.elasticsearch.xpack.ml.MachineLearning.createComponents(MachineLearning.java:497) ~[?:?]",
#"at org.elasticsearch.node.Node.lambda$new$9(Node.java:457) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at java.util.stream.ReferencePipeline$7$1.accept(ReferencePipeline.java:271) ~[?:?]",
#"at java.util.ArrayList$ArrayListSpliterator.forEachRemaining(ArrayList.java:1654) ~[?:?]",
#"at java.util.stream.AbstractPipeline.copyInto(AbstractPipeline.java:484) ~[?:?]",
#"at java.util.stream.AbstractPipeline.wrapAndCopyInto(AbstractPipeline.java:474) ~[?:?]",
#"at java.util.stream.ReduceOps$ReduceOp.evaluateSequential(ReduceOps.java:913) ~[?:?]",
#"at java.util.stream.AbstractPipeline.evaluate(AbstractPipeline.java:234) ~[?:?]",
#"at java.util.stream.ReferencePipeline.collect(ReferencePipeline.java:578) ~[?:?]",
#"at org.elasticsearch.node.Node.<init>(Node.java:460) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.node.Node.<init>(Node.java:258) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Bootstrap$5.<init>(Bootstrap.java:221) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:221) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:349) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:159) ~[elasticsearch-7.3.1.jar:7.3.1]",
#"... 6 more"] }

kubectl scale deployment elasticsearch --replicas=0
sleep 1
kubectl scale deployment elasticsearch --replicas=1
while :; do
   pod=`kubectl get pods -l io.kompose.service=elasticsearch -o jsonpath='{.items[0].metadata.name}'`
   kubectl exec -it $pod -- sh -c 'echo "xpack.ml.enabled: false" >> /usr/share/elasticsearch/config/elasticsearch.yml'
   if [ $? -eq 0 ]; then break; fi
done
