/**
 * CaseRoutingAction
 *
 * Invocable method called from a Record-Triggered Flow on Case insert.
 * Delegates all routing logic to CaseRoutingService and returns the
 * queue developer name so the Flow can look up the Group Id and set OwnerId.
 */
public with sharing class CaseRoutingAction {
  public class Request {
    @InvocableVariable(label='Case Subject' required=true)
    public String subject;

    @InvocableVariable(label='Case Description')
    public String description;
  }

  public class Result {
    @InvocableVariable(label='Queue Developer Name')
    public String queueDeveloperName;
  }

  @InvocableMethod(
    label='Resolve Case Queue'
    description='Returns the queue developer name based on the Case Subject and Description'
    category='Case'
  )
  public static List<Result> resolveQueue(List<Request> requests) {
    List<Result> results = new List<Result>();
    for (Request req : requests) {
      Result res = new Result();
      res.queueDeveloperName = CaseRoutingService.resolveQueue(req.subject, req.description);
      results.add(res);
    }
    return results;
  }
}
