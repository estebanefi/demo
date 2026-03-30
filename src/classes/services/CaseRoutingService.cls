/**
 * CaseRoutingService
 *
 * Determines which queue a Case belongs to based on its Subject and Description.
 * Intentionally decoupled from the Flow invocation layer (CaseRoutingAction) so
 * the resolution strategy can evolve independently — e.g. replaced with an AI
 * classification call — without touching the Flow integration.
 */
public with sharing class CaseRoutingService {
  public static final String QUEUE_POLICY_SERVICES = 'Policy_Services';
  public static final String QUEUE_BILLING_SUPPORT = 'Billing_Support';
  public static final String QUEUE_CLAIMS_INTAKE = 'Claims_Intake';

  /**
   * Returns the developer name of the queue that should own the Case.
   * When keywords from more than one queue are detected the case is
   * considered ambiguous and falls back to the default (Policy Services).
   *
   * @param subject     Case Subject field value
   * @param description Case Description field value
   * @return            Queue developer name (never null)
   */
  public static String resolveQueue(String subject, String description) {
    String text = ((subject ?? '') + ' ' + (description ?? '')).toLowerCase();

    // NOTE: Keywords are hardcoded here for demo simplicity.
    // In production, these should be stored in Custom Metadata (e.g. Queue_Routing_Keyword__mdt)
    // so routing rules can be managed by admins without a code deployment.
    Boolean matchesClaims = containsAny(text, new List<String>{ 'claim', 'loss', 'fnol', 'accident' });
    Boolean matchesBilling = containsAny(text, new List<String>{ 'billing', 'payment', 'invoice', 'premium' });
    Boolean matchesPolicy = containsAny(text, new List<String>{ 'policy', 'endorsement', 'cancellation', 'coverage' });

    Integer signalCount = (matchesClaims ? 1 : 0) + (matchesBilling ? 1 : 0) + (matchesPolicy ? 1 : 0);

    if (signalCount > 1) {
      return QUEUE_POLICY_SERVICES; // ambiguous — fall back to default
    }

    if (matchesClaims)
      return QUEUE_CLAIMS_INTAKE;
    if (matchesBilling)
      return QUEUE_BILLING_SUPPORT;

    return QUEUE_POLICY_SERVICES; // default
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  private static Boolean containsAny(String text, List<String> keywords) {
    for (String kw : keywords) {
      if (text.contains(kw))
        return true;
    }
    return false;
  }
}
