import Foundation

/// Votes to retry requests that fail with a transient error, using a fixed delay.
///
/// This interceptor decides **whether** an error is worth retrying — it does not
/// control the retry budget. The maximum number of attempts is configured once on
/// `HTTPClient.Configuration.maxRetries`, which is the single source of truth for
/// the retry count. Keeping the count out of this interceptor prevents the silent
/// `min(interceptor.maxRetries, config.maxRetries)` confusion that arises when both
/// sides set independent limits.
public struct RetryInterceptor: RequestInterceptorProtocol {
    private let delay: TimeInterval
    private let retryableStatusCodes: Set<Int>

    /// - Parameters:
    ///   - delay: Fixed delay in seconds before each retry attempt.
    ///   - retryableStatusCodes: HTTP status codes that should trigger a retry.
    public init(
        delay: TimeInterval = 1.0,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.delay = delay
        self.retryableStatusCodes = retryableStatusCodes
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        currentRetryCount: Int
    ) async -> RetryDecision {
        switch error {
        case .timeout, .noInternetConnection:
            return .retryWithDelay(delay)
        case .serverError(let code, _) where retryableStatusCodes.contains(code):
            return .retryWithDelay(delay)
        default:
            return .doNotRetry
        }
    }
}
