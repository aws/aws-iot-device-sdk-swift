# JobsSandbox

[**Return to main sample list**](../../README.md)

This is an interactive sample that supports a set of commands that allow you to interact with the AWS IoT [Jobs](https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html) Service.  The sample includes both control plane
commands (that require the AWS SDK for Swift and use HTTP as transport) and data plane commands (that use the device SDK and use MQTT as transport).  In a real use case,
control plane commands would be issued by applications under control of the customer, while the data plane operations would be issued by software running on the
IoT device itself.

Using the Jobs service and this sample requires an understanding of two closely-related but different service terms:
* **Job** - metadata describing a task that the user would like one or more devices to run
* **Job Execution** - metadata describing the state of a single device's attempt to execute a job

In particular, you could have many IoT devices (things) that belong to a thing group.  You could create a **Job** that targets the thing group.  Each device/thing would
manage its own individual **Job Execution** that corresponded to its attempt to fulfill the overall job request.  In the section that follows, notice that all of the data-plane
commands use `job-execution` while all of the control plane commands use `job`.

### Commands

Once connected, the sample supports the following commands:

Control Plane
* `create-job <jobId> <jobDocument-as-JSON>` - creates a new job resource that targets the thing/device the sample has been configured with.  It is up to the device application to interpret the Job document appropriately and carry out the execution it describes.
* `delete-job <jobId>` - delete a job.  A job must be in a terminal state (all executions terminal) for this command to complete successfully.

Data Plane
* `get-pending-job-executions` - gets the state of all incomplete job executions for this thing/device.
* `start-next-pending-job-execution` - if one or more pending job executions exist for this thing/device, attempts to transition the next one from QUEUED to IN_PROGRESS.  Returns information about the newly-in-progress job execution, if it exists.
* `describe-job-execution <jobId>` - gets the current state of this thing's execution of a particular job.
* `update-job-execution <jobId> <SUCCEEDED | IN_PROGRESS | FAILED | CANCELED>` - updates the status field of this thing's execution of a particular job.  SUCCEEDED, FAILED, and CANCELED are all terminal states.

Miscellaneous
* `help` - prints the set of supported commands
* `quit` - quits the sample application

### Prerequisites
Your IoT Core Thing's [Policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html) must provide privileges for this sample to connect, subscribe, publish, and receive. Below is a sample policy that can be used on your IoT Core Thing that will allow this sample to run as intended.

<details>
<summary>Sample Policy</summary>
<pre>
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:Publish",
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/start-next",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/*/update",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/*/get",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/get"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Receive",
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/notify",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/notify-next",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/start-next/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/*/update/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/get/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/jobs/*/get/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Subscribe",
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/notify",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/notify-next",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/start-next/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/*/update/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/get/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/jobs/*/get/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:Connect",
      "Resource": "arn:aws:iot:<b>region</b>:<b>account</b>:client/test-*"
    }
  ]
}
</pre>

Replace with the following with the data from your AWS account:
* `<region>`: The AWS IoT Core region where you created your AWS IoT Core thing you wish to use with this sample. For example `us-east-1`.
* `<account>`: Your AWS IoT Core account ID. This is the set of numbers in the top right next to your AWS account name when using the AWS IoT Core website.
* `<thingname>`: The name of your AWS IoT Core thing you want the device connection to be associated with

Note that in a real application, you may want to avoid the use of wildcards in your ClientID or use them selectively. Please follow best practices when working with AWS on production applications using the SDK. Also, for the purposes of this sample, please make sure your policy allows a client ID of `test-*` to connect or use `--client_id <client ID here>` to send the client ID your policy supports.

</details>

Additionally, the sample's control plane operations require that AWS credentials with appropriate permissions be sourceable by the default credentials provider chain
of the Swift SDK.  At a minimum, the following permissions must be granted:
<details>
<summary>Sample Policy</summary>
<pre>
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:CreateJob",
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:job/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:thing/<b>thingname</b>"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iot:DeleteJob",
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:job/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:thing/<b>thingname</b>"
      ]
    }
  ]
}
</pre>

Replace with the following with the data from your AWS account:
* `<region>`: The AWS IoT Core region where you created your AWS IoT Core thing you wish to use with this sample. For example `us-east-1`.
* `<account>`: Your AWS IoT Core account ID. This is the set of numbers in the top right next to your AWS account name when using the AWS IoT Core website.
* `<thingname>`: The name of your AWS IoT Core thing you want the device connection to be associated with

Notice that you must provide `iot:CreateJob` permission to all things targeted by your jobs as well as the job itself.  In this example, we use a wildcard for the
job permission so that you can name the jobs whatever you would like.

</details>

## Walkthrough

### Run the Sample

To run the Jobs sample use the following command:

``` sh
swift run JobsSample \
     <endpoint> \
     <path to certificate> \
     <path to private key> \
     "<region>" \
     "<thing name>"
```

If an AWS IoT Thing resource with the given name does not exist, the sample will first create it.  Once the thing
exists, the sample connects via MQTT and you can issue commands to the Jobs service and inspect the results.  This walkthrough assumes a fresh thing
that has no pre-existing jobs targeting it.

### Job Creation
First, we check if there are any incomplete job executions for this device.  Assuming the thing is freshly-created, we expect there to be nothing:

```
get-pending-job-executions
```
yields output like
```
─── GetPendingJobExecutionsResponse ─────────────────────────────────────────────────
{
  "clientToken" : "B604742A-6827-4BFF-B187-6A9F255DF66F",
  "inProgressJobs" : [

  ],
  "queuedJobs" : [

  ],
  "timestamp" : 1748981603
}
```
from which we can see that the device has no pending job executions and no in-progress job executions.

Next, we'll create a couple of jobs that target the device:

```
create-job Job1 {"Todo":"Reboot"}
```

which yields output similar to

```
─── CreateJobOutput ─────────────────────────────────────────────────
description: <nil>
jobArn: arn:aws:iot:us-east-1:123124136734:job/Job1
jobId: Job1
  
─── JobExecutionsChangedEvent ───────────────────────────────────────────
{
  "jobs" : {
    "QUEUED" : [
      {
        "executionNumber" : 1,
        "jobId" : "Job1",
        "lastUpdatedAt" : 1748981622,
        "queuedAt" : 1748981622,
        "versionNumber" : 1
      }
    ]
  },
  "timestamp" : 1748981622
}

─── NextJobExecutionChangedEvent ───────────────────────────────────────────
{
  "execution" : {
    "executionNumber" : 1,
    "jobDocument" : {
      "Todo" : "Reboot"
    },
    "jobId" : "Job1",
    "lastUpdatedAt" : 1748981622,
    "queuedAt" : 1748981622,
    "startedAt" : null,
    "status" : "QUEUED",
    "statusDetails" : null,
    "thingName" : null,
    "versionNumber" : 1
  },
  "timestamp" : 1748981622
}
```

In addition to the successful (HTTP) response to the CreateJob API call, our action triggered two (MQTT-based) events: a JobExecutionsChangedEvent and a
NextJobExecutionChangedEvent.  When the sample is run, it creates and opens two streaming operations that listen for these two different events, by using the
`createJobExecutionsChangedStream` and `createNextJobExecutionChangedStream` APIs.

A JobExecutionsChangedEvent is emitted every time either the queued or in-progress job execution sets change for the device.  A NextJobExecutionChangedEvent is emitted
only when the next job to be executed changes.  So if you create N jobs targeting a device, you'll get N JobExecutionsChanged events, but only (up to) one
NextJobExecutionChanged event (unless the device starts completing jobs, triggering additional NextJobExecutionChanged events).

Let's create a second job as well:

```
create-job Job2 {"ToDo":"Delete Root User"}
```

whose output might look like

```
─── CreateJobOutput ─────────────────────────────────────────────────
description: <nil>
jobArn: arn:aws:iot:us-east-1:123124136734:job/Job2
jobId: Job2

─── JobExecutionsChangedEvent ───────────────────────────────────────────
{
  "jobs" : {
    "QUEUED" : [
      {
        "executionNumber" : 1,
        "jobId" : "Job1",
        "lastUpdatedAt" : 1748981622,
        "queuedAt" : 1748981622,
        "versionNumber" : 1
      },
      {
        "executionNumber" : 1,
        "jobId" : "Job2",
        "lastUpdatedAt" : 1748981704,
        "queuedAt" : 1748981704,
        "versionNumber" : 1
      }
    ]
  },
  "timestamp" : 1748981706
}
```

Notice how this time, there is no NextJobExecutionChanged event because the second job is behind the first, and therefore the next job execution hasn't changed.  As we will
see below, a NextJobExecutionChanged event referencing the second job will be emitted when the first job (in progress) is completed.

### Job Execution
Our device now has two jobs queued that it needs to (pretend to) execute.  Let's see how to do that, and what happens when we do.

The easiest way to start a job execution is via the `startNextPendingJobExecution` API.  This API takes the job execution at the head of the QUEUED list and moves it
into the IN_PROGRESS state, returning its job document in the process.

```
start-next-pending-job-execution
```
```
─── StartNextJobExecutionResponse ─────────────────────────────────────────────────
{
  "clientToken" : "A35D3C3B-D8A2-41ED-B9C0-B893105B355D",
  "execution" : {
    "executionNumber" : 1,
    "jobDocument" : {
      "Todo" : "Reboot"
    },
    "jobId" : "Job1",
    "lastUpdatedAt" : 1748981741,
    "queuedAt" : 1748981622,
    "startedAt" : 1748981741,
    "status" : "IN_PROGRESS",
    "statusDetails" : null,
    "thingName" : null,
    "versionNumber" : 2
  },
  "timestamp" : 1748981741
}
```
Note that the response includes the job's document, which is what describes what the job actually entails.  The contents of the job document and its interpretation and
execution are the responsibility of the developer.  Notice also that no events were emitted from the action of moving a job from the QUEUED state to the IN_PROGRESS state.

If we run `getPendingJobExecutions` again, we see that Job1 is now in progress, while Job2 remains in the queued state:

```
get-pending-job-executions
```
```
─── GetPendingJobExecutionsResponse ─────────────────────────────────────────────────
{
  "clientToken" : "72226AF8-1C7F-497D-A32E-3DE74CA27DCD",
  "inProgressJobs" : [
    {
      "executionNumber" : 1,
      "jobId" : "Job1",
      "lastUpdatedAt" : 1748981741,
      "queuedAt" : 1748981622,
      "startedAt" : 1748981741,
      "versionNumber" : 2
    }
  ],
  "queuedJobs" : [
    {
      "executionNumber" : 1,
      "jobId" : "Job2",
      "lastUpdatedAt" : 1748981704,
      "queuedAt" : 1748981704,
      "versionNumber" : 1
    }
  ],
  "timestamp" : 1748981785
}
```

A real device application would perform the job execution steps as needed.  Let's assume that has been done.  We need to tell the service the job has
completed:

```
update-job-execution Job1 SUCCEEDED
```
will trigger output similar to
```
─── UpdateJobExecutionResult ─────────────────────────────────────────────────
{
  "executionState" : null,
  "timestamp" : 1748981892
}
  
─── NextJobExecutionChangedEvent ───────────────────────────────────────────
{
  "execution" : {
    "executionNumber" : 1,
    "jobDocument" : {
      "ToDo" : "Delete Root User"
    },
    "jobId" : "Job2",
    "lastUpdatedAt" : 1748981704,
    "queuedAt" : 1748981704,
    "startedAt" : null,
    "status" : "QUEUED",
    "statusDetails" : null,
    "thingName" : null,
    "versionNumber" : 1
  },
  "timestamp" : 1748981893
}

─── JobExecutionsChangedEvent ───────────────────────────────────────────
{
  "jobs" : {
    "QUEUED" : [
      {
        "executionNumber" : 1,
        "jobId" : "Job2",
        "lastUpdatedAt" : 1748981704,
        "queuedAt" : 1748981704,
        "versionNumber" : 1
      }
    ]
  },
  "timestamp" : 1748981892
}
```
Notice we get a response as well as two events, since both
1. The set of incomplete job executions set has changed.
1. The next job to be executed has changed.

As expected, we can move Job2's execution into IN_PROGRESS by invoking `startNextPendingJobExecution` again:

```
start-next-pending-job-execution
```
```
─── StartNextJobExecutionResponse ─────────────────────────────────────────────────
{
  "clientToken" : "59A22279-5E7D-4C7B-BCC4-934F6DEBF26E",
  "execution" : {
    "executionNumber" : 1,
    "jobDocument" : {
      "ToDo" : "Delete Root User"
    },
    "jobId" : "Job2",
    "lastUpdatedAt" : 1748982154,
    "queuedAt" : 1748981704,
    "startedAt" : 1748982154,
    "status" : "IN_PROGRESS",
    "statusDetails" : null,
    "thingName" : null,
    "versionNumber" : 2
  },
  "timestamp" : 1748982154
}
```

Let's pretend that the job execution failed.  An update variant can notify the Jobs service of this fact:

```
update-job-execution Job2 FAILED
```
triggering
```
─── UpdateJobExecutionResult ─────────────────────────────────────────────────
{
  "executionState" : null,
  "timestamp" : 1748982170
}
  
─── JobExecutionsChangedEvent ───────────────────────────────────────────
{
  "jobs" : {

  },
  "timestamp" : 1748982171
}

─── NextJobExecutionChangedEvent ───────────────────────────────────────────
{
  "timestamp" : 1748982171
}
```
At this point, no incomplete job executions remain.

### Job Cleanup
When all executions for a given job have reached a terminal state (SUCCEEDED, FAILED, CANCELED), you can delete the job itself.  This is a control plane operation
that requires the AWS SDK for Swift and should not be performed by the device executing jobs:

```
delete-job Job1
```

### Misc. Topics
#### What happens if I call `startNextPendingJobExecution` and there are no jobs to execute?
The request will not fail, but the `execution` field of the response will be empty, indicating that there is nothing to do.

#### What happens if I call `startNextPendingJobExecution` twice in a row (or while another job is in the IN_PROGRESS state)?
The service will return the execution information for the IN_PROGRESS job again.

#### What if I want my device to handle multiple job executions at once?
Since `startNextPendingJobExecution` does not help here, the device application can manually update a job execution from the QUEUED state to the IN_PROGRESS
state in the same manner that it completes a job execution: use `getPendingJobExecutions` to get the list of queued executions and use
`updateJobExecution` to move one or more job executions into the IN_PROGRESS state.

#### What is the proper generic architecture for a job-processing application running on a device?
A device's persistent job executor should:
1. On startup, create and open streaming operations for both the JobExecutionsChanged and NextJobExecutionChanged events
2. On startup, get and cache the set of incomplete job executions using `getPendingJobExecutions`
3. Keep the cached job execution set up to date by reacting appropriately to JobExecutionsChanged and NextJobExecutionChanged events
4. While there are incomplete job executions, start and execute them one-at-a-time; otherwise wait for a new entry in the incomplete (queued) job executions set.