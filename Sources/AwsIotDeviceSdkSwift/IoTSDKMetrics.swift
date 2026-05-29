///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit
import Foundation

// MARK: - IoT SDK Feature ID Constants

/// Feature IDs for IoT SDK metrics tracking at the SDK layer.
/// These IDs are used to encode feature usage in the metrics string.
///
/// Note: Feature IDs A-H and J-K are tracked at the CRT layer (aws-crt-swift).
/// The IoT SDK layer tracks feature ID I (certificate_source).
enum IoTSDKFeatureId {
  /// Certificate source feature ID (tracked at IoT SDK level)
  static let certificateSource: Character = "I"
}

// MARK: - Certificate Source

/// Represents the source of the certificate used for mTLS authentication.
/// This is tracked as feature ID "I" in the metrics.
enum CertificateSource: Sendable {
  /// Certificate and key loaded from file paths
  case certificateFiles
  /// Certificate and key loaded from PKCS#11 hardware token
  case pkcs11
  /// Certificate loaded from Windows Certificate Store
  case windowsCertStore
  /// Certificate loaded from Java KeyStore
  case javaKeyStore
  /// Certificate loaded from PKCS#12 file
  case pkcs12File

  /// Converts to metrics value character.
  /// Values: A=CERTIFICATE_FILES, B=PKCS11, C=WINDOWS_CERT_STORE, D=JAVA_KEYSTORE, E=PKCS12_FILE
  var metricsValue: Character {
    switch self {
    case .certificateFiles: return "A"
    case .pkcs11: return "B"
    case .windowsCertStore: return "C"
    case .javaKeyStore: return "D"
    case .pkcs12File: return "E"
    }
  }
}

// MARK: - IoT SDK Metrics Feature List

/// Tracks SDK-level features for metrics reporting.
/// This struct collects feature flags that are set during client builder configuration.
struct IoTSDKMetricsFeatureList: Sendable {
  /// The certificate source used for mTLS authentication (if applicable)
  public var certificateSource: CertificateSource?

  /// Creates an empty feature list
  public init() {}

  /// Creates a feature list with a certificate source
  /// - Parameter certificateSource: The certificate source to track
  public init(certificateSource: CertificateSource?) {
    self.certificateSource = certificateSource
  }

  /// Generates the encoded feature list string for the IoT SDK layer.
  /// The format is ID/Value pairs separated by commas.
  /// Example: "I/A" means Feature I (certificate_source) with value A (CERTIFICATE_FILES)
  ///
  /// - Returns: The encoded feature list string, or empty string if no features are set
  func getEncodedFeatureList() -> String {
    var features: [String] = []

    // I: certificate_source
    if let certSource = certificateSource {
      features.append("\(IoTSDKFeatureId.certificateSource)/\(certSource.metricsValue)")
    }

    return features.joined(separator: ",")
  }
}

// MARK: - IoT SDK Metrics Builder

/// Helper class for building IoTDeviceSDKMetrics from SDK-level configuration.
/// This class creates the metrics structure that will be passed to the CRT layer.
class IoTSDKMetricsBuilder {

  /// The current version of the IoT SDK metrics format
  /// This must match the version expected by the CRT layer
  private static let metricsVersion: Int = 1

  /// Creates IoTDeviceSDKMetrics from the SDK feature list.
  /// The metrics will include:
  /// - IoTSDKVersion: The version of the IoT Device SDK
  /// - IoTSDKFeature: The encoded feature list from the SDK layer
  /// - IoTSDKMetricsVersion: The metrics format version
  ///
  /// - Parameter featureList: The SDK-level feature list to encode
  /// - Returns: IoTDeviceSDKMetrics configured with SDK-level metadata
  public static func createMetrics(from featureList: IoTSDKMetricsFeatureList)
    -> IoTDeviceSDKMetrics
  {
    let metrics = IoTDeviceSDKMetrics()

    // Set IoTSDKVersion
    metrics.metadata["IoTSDKVersion"] = packageVersion

    // Set IoTSDKFeature if there are any features to report
    let encodedFeatures = featureList.getEncodedFeatureList()
    if !encodedFeatures.isEmpty {
      metrics.metadata["IoTSDKFeature"] = encodedFeatures
    }

    // Set IoTSDKMetricsVersion
    metrics.metadata["IoTSDKMetricsVersion"] = String(metricsVersion)

    return metrics
  }
}
