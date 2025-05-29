# Shadow

[**Return to main sample list**](../../README.md)

This is an interactive sample that supports a set of commands that allow you to interact with "classic" (unnamed) shadows of the AWS IoT [Device Shadow](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html) Service.

### Commands
Once connected, the sample supports the following shadow-related commands:

* `get` - gets the current full state of the classic (unnamed) shadow.  This includes both a "desired" state component and a "reported" state component.
* `delete` - deletes the classic (unnamed) shadow completely
* `update-desired <desired-state-json-document>` - applies an update to the classic shadow's desired state component.  Properties in the JSON document set to non-null will be set to new values.  Properties in the JSON document set to null will be removed.
* `update-reported <reported-state-json-document>` - applies an update to the classic shadow's reported state component.  Properties in the JSON document set to non-null will be set to new values.  Properties in the JSON document set to null will be removed.

Three additional commands are supported:
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
      "Action": [
        "iot:Publish"
      ],
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/get",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/delete",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/update"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Receive"
      ],
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/get/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/delete/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topic/$aws/things/<b>thingname</b>/shadow/update/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Subscribe"
      ],
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/shadow/get/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/shadow/delete/*",
        "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/$aws/things/<b>thingname</b>/shadow/update/*"
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

## Walkthrough

To run the Shadow sample use the following command from the Samples/ServiceClientSamples/ShadowSample directory:

``` sh
swift run ShadowSample \
     <endpoint> \
     <path to certificate> \
     <path to private key> \
     "<thing name>"
```

The sample also listens to a pair of event streams related to the classic (unnamed) shadow state of your thing, so in addition to responses, you will occasionally see output from these streaming operations as they receive events from the shadow service.

Once successfully connected, you can issue commands.

### Initialization

Start off by getting the shadow state:

```
get
```

If your thing does have shadow state, you will get its current value, which this sample has no control over.  

If your thing does not have any shadow state, you'll get a Service Request Rejected error:

```
─── Service Request Rejected ────────────────────────────
code:        404
message:     No shadow exists with name: '<thing name>'
```

To create a shadow, you can issue an update call that will initialize the shadow to a starting state:

```
update-reported {"Color":"green"}
```

which will yield output similar to:

```
─── UpdateShadowResponse ────────────────────────────────────────────
{
  "clientToken" : "E47FEB1E-0801-4737-B4AF-9B9B7671D526",
  "metadata" : {
    "reported" : {
      "Color" : {
        "timestamp" : 1748532187
      }
    }
  },
  "state" : {
    "reported" : {
      "Color" : "green"
    }
  },
  "timestamp" : 1748532187,
  "version" : 110
}

─── ShadowUpdatedEvent ────────────────────────────────────────────────
{
  "current" : {
    "metadata" : {
      "reported" : {
        "Color" : {
          "timestamp" : 1748532187
        }
      }
    },
    "state" : {
      "reported" : {
        "Color" : "green"
      }
    },
    "version" : 110
  },
  "previous" : {
    "metadata" : {

    },
    "state" : {

    },
    "version" : 109
  },
  "timestamp" : 1748532187
}
```

Notice that in addition to receiving a response to the update request, you also receive a `ShadowUpdatedEvent` event containing what changed about
the shadow. The `ShadowUpdatedEvent` received in the streaming operation event contains additional metadata (version, update timestamps, etc...).  Every time a shadow is updated, this
event is triggered.  If you wish to listen and react to this event, use the `createShadowUpdatedStream` API in the shadow client to create a
streaming operation that converts the raw MQTT publish messages into modeled data that the streaming operation emits.

Issue one more update to get the shadow's reported and desired states in sync:

```
update-desired {"Color":"green"}
```

yielding output similar to:

```
─── UpdateShadowResponse ────────────────────────────────────────────
{
  "clientToken" : "EFDB257C-03A4-4DA6-A095-AB28198A0E97",
  "metadata" : {
    "desired" : {
      "Color" : {
        "timestamp" : 1748532364
      }
    }
  },
  "state" : {
    "desired" : {
      "Color" : "green"
    }
  },
  "timestamp" : 1748532364,
  "version" : 111
}

─── ShadowUpdatedEvent ────────────────────────────────────────────────
<ShadowUpdated event omitted>
```

### Changing Properties
A device shadow contains two independent states: reported and desired.  "Reported" represents the device's last-known local state, while
"desired" represents the state that control application(s) would like the device to change to.  In general, each application (whether on the device or running
remotely as a control process) will only update one of these two state components.

Let's walk through the multi-step process to coordinate a change-of-state on the device.  First, a control application needs to update the shadow's desired
state with the change it would like applied:

```
update-desired {"Color":"red"}
```

For our sample, this yields output similar to:

```
─── ShadowDeltaUpdatedEvent ───────────────────────────────────────────
{
  "metadata" : {
    "Color" : {
      "timestamp" : 1748532523
    }
  },
  "state" : {
    "Color" : "red"
  },
  "timestamp" : 1748532523,
  "version" : 112
}

─── ShadowUpdatedEvent ────────────────────────────────────────────────
{
  "current" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532523
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532187
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "red"
      },
      "reported" : {
        "Color" : "green"
      }
    },
    "version" : 112
  },
  "previous" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532364
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532187
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "green"
      },
      "reported" : {
        "Color" : "green"
      }
    },
    "version" : 111
  },
  "timestamp" : 1748532523
}

─── UpdateShadowResponse ────────────────────────────────────────────
{
  "clientToken" : "BDA5C2F7-8750-4AF1-8271-25EF7DE948F9",
  "metadata" : {
    "desired" : {
      "Color" : {
        "timestamp" : 1748532523
      }
    }
  },
  "state" : {
    "desired" : {
      "Color" : "red"
    }
  },
  "timestamp" : 1748532523,
  "version" : 112
}
```

The key thing to notice here is that in addition to the update response (which only the control application would see) and the ShadowUpdated event,
there is a new event, 'ShadowDeltaUpdatedEvent', which indicates properties on the shadow that are out-of-sync between desired and reported.  All out-of-sync
properties will be included in this event, including properties that became out-of-sync due to a previous update.

Like the ShadowUpdated event, ShadowDeltaUpdated events can be listened to by creating and configuring a streaming operation, this time by using
the createShadowDeltaUpdatedStream API.  Using the `ShadowDeltaUpdatedEvent` events (rather than ShadowUpdated) lets a device focus on just what has
changed without having to do complex JSON diffs on the full shadow state itself.

Assuming that the change expressed in the desired state is reasonable, the device should apply it internally and then let the service know it
has done so by updating the reported state of the shadow:

```
update-reported {"Color":"red"}
```

yielding

```
─── ShadowUpdatedEvent ────────────────────────────────────────────────
{
  "current" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532523
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532650
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "red"
      },
      "reported" : {
        "Color" : "red"
      }
    },
    "version" : 113
  },
  "previous" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532523
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532187
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "red"
      },
      "reported" : {
        "Color" : "green"
      }
    },
    "version" : 112
  },
  "timestamp" : 1748532650
}

─── UpdateShadowResponse ────────────────────────────────────────────
{
  "clientToken" : "6A77010C-B355-400C-8BA5-FFE6212337B5",
  "metadata" : {
    "reported" : {
      "Color" : {
        "timestamp" : 1748532650
      }
    }
  },
  "state" : {
    "reported" : {
      "Color" : "red"
    }
  },
  "timestamp" : 1748532650,
  "version" : 113
}
```

Notice that no ShadowDeltaUpdated event is generated because the reported and desired states are now back in sync.

### Multiple Properties
Not all shadow properties represent device configuration.  To illustrate several more aspects of the Shadow service, let's add a second property to our shadow document,
starting out in sync (output omitted):

```
update-reported {"Status":"Great"}
```

```
update-desired {"Status":"Great"}
```

Notice that shadow updates work by deltas rather than by complete state changes.  Updating the "Status" property to a value had no effect on the shadow's
"Color" property:

```
get
```

yields

```
─── GetShadowResponse ─────────────────────────────────────────────────
{
  "clientToken" : "63EA0DA7-2159-44D0-B0A3-66B27701C7E6",
  "metadata" : {
    "desired" : {
      "Color" : {
        "timestamp" : 1748532523
      },
      "Status" : {
        "timestamp" : 1748532687
      }
    },
    "reported" : {
      "Color" : {
        "timestamp" : 1748532650
      },
      "Status" : {
        "timestamp" : 1748532682
      }
    }
  },
  "state" : {
    "desired" : {
      "Color" : "red",
      "Status" : "Great"
    },
    "reported" : {
      "Color" : "red",
      "Status" : "Great"
    }
  },
  "timestamp" : 1748532689,
  "version" : 115
}
```

Suppose something goes wrong with the device and its status is no longer "Great"

```
update-reported {"Status":"Awful"}
```

which yields output similar to:

```
─── ShadowDeltaUpdatedEvent ───────────────────────────────────────────
{
  "metadata" : {
    "Status" : {
      "timestamp" : 1748532687
    }
  },
  "state" : {
    "Status" : "Great"
  },
  "timestamp" : 1748532722,
  "version" : 116
}

─── ShadowUpdatedEvent ────────────────────────────────────────────────
{
  "current" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532523
        },
        "Status" : {
          "timestamp" : 1748532687
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532650
        },
        "Status" : {
          "timestamp" : 1748532722
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "red",
        "Status" : "Great"
      },
      "reported" : {
        "Color" : "red",
        "Status" : "Awful"
      }
    },
    "version" : 116
  },
  "previous" : {
    "metadata" : {
      "desired" : {
        "Color" : {
          "timestamp" : 1748532523
        },
        "Status" : {
          "timestamp" : 1748532687
        }
      },
      "reported" : {
        "Color" : {
          "timestamp" : 1748532650
        },
        "Status" : {
          "timestamp" : 1748532682
        }
      }
    },
    "state" : {
      "desired" : {
        "Color" : "red",
        "Status" : "Great"
      },
      "reported" : {
        "Color" : "red",
        "Status" : "Great"
      }
    },
    "version" : 115
  },
  "timestamp" : 1748532722
}

─── UpdateShadowResponse ────────────────────────────────────────────
{
  "clientToken" : "1C63ACF4-3704-486B-B130-4D09DABBEAC2",
  "metadata" : {
    "reported" : {
      "Status" : {
        "timestamp" : 1748532722
      }
    }
  },
  "state" : {
    "reported" : {
      "Status" : "Awful"
    }
  },
  "timestamp" : 1748532722,
  "version" : 116
}
```

Similar to how updates are delta-based, notice how the ShadowDeltaUpdated event only includes the "Status" property, leaving the "Color" property out because it
is still in sync between desired and reported.

### Removing properties
Properties can be removed from a shadow by setting them to null.  Removing a property completely would require its removal from both the
reported and desired states of the shadow (output omitted):

```
update-reported {"Status":null}
```

```
update-desired {"Status":null}
```

If you now get the shadow state:

```
get
```

its output yields something like

```
─── GetShadowResponse ─────────────────────────────────────────────────
{
  "clientToken" : "DE9701A4-1E67-4EBC-B6FB-3E094E91C4E2",
  "metadata" : {
    "desired" : {
      "Color" : {
        "timestamp" : 1748532523
      }
    },
    "reported" : {
      "Color" : {
        "timestamp" : 1748532650
      }
    }
  },
  "state" : {
    "desired" : {
      "Color" : "red"
    },
    "reported" : {
      "Color" : "red"
    }
  },
  "timestamp" : 1748532809,
  "version" : 118
}
```

The Status property has been fully removed from the shadow state.

### Removing a shadow
To remove a shadow, you must invoke the DeleteShadow API (setting the reported and desired
states to null will only clear the states, but not delete the shadow resource itself).

```
delete
```

yields something like

```
─── DeleteShadowResponse ──────────────────────────────────────────────
{
  "clientToken" : "1CCF6068-CD1B-4C54-9D26-7E3D629C76DC",
  "timestamp" : 1748532826,
  "version" : 118
}
```