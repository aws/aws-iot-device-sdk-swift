public enum AwsIotDeviceSdkError : Error {
    case configurationError(reason: String)
    case missingParameter(parameterName: String)
    case serviceClientError(reason: String)
}