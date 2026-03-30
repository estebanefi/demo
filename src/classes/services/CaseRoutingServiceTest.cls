@IsTest
private class CaseRoutingServiceTest {
  // ─── Claims Intake ────────────────────────────────────────────────────────

  @IsTest
  static void testClaimsKeyword_claim() {
    String result = CaseRoutingService.resolveQueue('I need to file a claim', null);
    System.assertEquals(CaseRoutingService.QUEUE_CLAIMS_INTAKE, result);
  }

  @IsTest
  static void testClaimsKeyword_loss() {
    String result = CaseRoutingService.resolveQueue('First notice of loss', null);
    System.assertEquals(CaseRoutingService.QUEUE_CLAIMS_INTAKE, result);
  }

  @IsTest
  static void testClaimsKeyword_fnol() {
    String result = CaseRoutingService.resolveQueue(null, 'FNOL submitted via web form');
    System.assertEquals(CaseRoutingService.QUEUE_CLAIMS_INTAKE, result);
  }

  @IsTest
  static void testClaimsKeyword_accident() {
    String result = CaseRoutingService.resolveQueue('Accident report', 'I was in an accident yesterday');
    System.assertEquals(CaseRoutingService.QUEUE_CLAIMS_INTAKE, result);
  }

  // ─── Billing Support ─────────────────────────────────────────────────────

  @IsTest
  static void testBillingKeyword_billing() {
    String result = CaseRoutingService.resolveQueue('Billing question', null);
    System.assertEquals(CaseRoutingService.QUEUE_BILLING_SUPPORT, result);
  }

  @IsTest
  static void testBillingKeyword_payment() {
    String result = CaseRoutingService.resolveQueue('Payment failed', 'My payment did not go through');
    System.assertEquals(CaseRoutingService.QUEUE_BILLING_SUPPORT, result);
  }

  @IsTest
  static void testBillingKeyword_invoice() {
    String result = CaseRoutingService.resolveQueue(null, 'I have a question about my invoice');
    System.assertEquals(CaseRoutingService.QUEUE_BILLING_SUPPORT, result);
  }

  @IsTest
  static void testBillingKeyword_premium() {
    String result = CaseRoutingService.resolveQueue('Premium amount incorrect', null);
    System.assertEquals(CaseRoutingService.QUEUE_BILLING_SUPPORT, result);
  }

  // ─── Policy Services ─────────────────────────────────────────────────────

  @IsTest
  static void testPolicyKeyword_policy() {
    String result = CaseRoutingService.resolveQueue('Update my policy', null);
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  @IsTest
  static void testPolicyKeyword_endorsement() {
    String result = CaseRoutingService.resolveQueue('Policy endorsement request', null);
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  @IsTest
  static void testPolicyKeyword_cancellation() {
    String result = CaseRoutingService.resolveQueue(null, 'I would like to request a cancellation');
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  @IsTest
  static void testPolicyKeyword_coverage() {
    String result = CaseRoutingService.resolveQueue('Coverage question', 'What does my coverage include?');
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  // ─── Default (no keyword match) ───────────────────────────────────────────

  @IsTest
  static void testDefaultsWhenNoKeywordMatch() {
    String result = CaseRoutingService.resolveQueue('General enquiry', 'I have a question about my account');
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  @IsTest
  static void testDefaultsWhenBothInputsNull() {
    String result = CaseRoutingService.resolveQueue(null, null);
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  @IsTest
  static void testDefaultsWhenBothInputsBlank() {
    String result = CaseRoutingService.resolveQueue('', '');
    System.assertEquals(CaseRoutingService.QUEUE_POLICY_SERVICES, result);
  }

  // ─── Ambiguous (mixed keywords → default) ────────────────────────────────

  @IsTest
  static void testAmbiguous_claimAndPayment() {
    String result = CaseRoutingService.resolveQueue(
      'Question about my claim payment',
      'I received a settlement on my claim but have a question about the payment amount.'
    );
    System.assertEquals(
      CaseRoutingService.QUEUE_POLICY_SERVICES,
      result,
      'Mixed claim+payment signals should default to Policy Services'
    );
  }

  @IsTest
  static void testAmbiguous_policyAndClaim() {
    String result = CaseRoutingService.resolveQueue(
      'Policy claim question',
      'I want to file a claim related to my policy'
    );
    System.assertEquals(
      CaseRoutingService.QUEUE_POLICY_SERVICES,
      result,
      'Mixed policy+claim signals should default to Policy Services'
    );
  }

  @IsTest
  static void testAmbiguous_allThreeQueues() {
    String result = CaseRoutingService.resolveQueue(
      'Billing claim policy',
      'This message contains keywords from every queue'
    );
    System.assertEquals(
      CaseRoutingService.QUEUE_POLICY_SERVICES,
      result,
      'All-queue signals should default to Policy Services'
    );
  }

  // ─── Case-insensitivity ───────────────────────────────────────────────────

  @IsTest
  static void testCaseInsensitive_uppercaseClaim() {
    String result = CaseRoutingService.resolveQueue('CLAIM FILED', null);
    System.assertEquals(CaseRoutingService.QUEUE_CLAIMS_INTAKE, result);
  }

  @IsTest
  static void testCaseInsensitive_mixedCasePayment() {
    String result = CaseRoutingService.resolveQueue('PaYmEnT IsSuE', null);
    System.assertEquals(CaseRoutingService.QUEUE_BILLING_SUPPORT, result);
  }

  // ─── Keyword in description only ─────────────────────────────────────────

  @IsTest
  static void testKeywordInDescriptionOnly() {
    String result = CaseRoutingService.resolveQueue('Help needed', 'I need to report an accident');
    System.assertEquals(
      CaseRoutingService.QUEUE_CLAIMS_INTAKE,
      result,
      'Keyword in Description alone should route correctly'
    );
  }

  @IsTest
  static void testKeywordInSubjectOnly() {
    String result = CaseRoutingService.resolveQueue('Invoice discrepancy', 'Please help me resolve this');
    System.assertEquals(
      CaseRoutingService.QUEUE_BILLING_SUPPORT,
      result,
      'Keyword in Subject alone should route correctly'
    );
  }
}
