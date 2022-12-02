# AzureReservedInstanceNotifier
A solution utilizing Logic Apps to create custom notifications about Azure Reservation expiry.

While it is not always possible to grant the requisite users the necessary access to Azure Portal, and since by default Azure Reservations notify a limited number of users regarding pending expirations, this solution was created in order to more granularly control when these notifications are sent, and to whom.

# Overview

The solution consists of (fairly monolithic) LogicApp, which can be triggered through an HTTP request with a number of parameters.

The main LogicApp uses a [managed identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) to access the Azure Management API: specifically, [Reservation Order List](https://learn.microsoft.com/en-us/rest/api/reserved-vm-instances/reservation-order/list) and [Reservation Get](https://learn.microsoft.com/en-us/rest/api/reserved-vm-instances/reservation/get).

(for reference purposes, I was not able to use the Reservation Orders `GET` due to what I'm assuming was a bug, which [has now been fixed](https://stackoverflow.com/questions/73815802/azure-management-api-not-returning-reserved-instances))

# Installation and configuration

1. Deploy a LogicApp, and [assign it a System-Assigned Managed Identity](https://learn.microsoft.com/en-us/azure/logic-apps/create-managed-service-identity?tabs=consumption).
2. Next you have to grant this MI the requisite rights to view information for reservations. This can be done through Role Assignment in the Reservations blade:

![image](https://user-images.githubusercontent.com/3426823/205326497-3877420a-4fa6-41ad-aec2-e25a5fae4c29.png)

and assigning your MI the **Reservations Reader** role:

![image](https://user-images.githubusercontent.com/3426823/205326697-116989cc-6628-4925-8ce1-9bf8d519dc4d.png)

Note that you will only be able to assign this Role if your account [has been elevated](https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin).

3. Copy the code from the JSON file into the code-view, and configure the Send Email task to use your credentials.

After this, you can invoke the LogicApp manually, or via a separate LogicApp to trigger it based on a Recurrence trigger.

# Parameters

## `action`

### `audit`

Compiles a digest of all reservations. This mode is invoked by supplying `audit` to the `action` parameter. 

When running in audit mode, you can further refine the returned results by specifying whether only non-expired reservations should be returned, by supplying `true` for `activeOnly`:

Sample payload:

```
{    
    // Set Action to audit
    "action": "audit",
    // Return all reservations, regardless of status
    "activeOnly": false,    
    // Set the context (this will be included in the output email)
    "identifier": "My company name",    
    // Semi-colon separated list of email addresses to send email to
    "emailResultsTo": "test@zero.co.zip"
}
```

### `monitor`

Identifies reservations expiring within a configurable set of parameters. This mode is invoked by supplying `monitor` to the `action` parameter.

When running in monitor mode, you can specify the maximum and minimum for two ranges, based on the amount of days until reservations expire.

```
{
    // Set Action to monitor
    "action": "monitor",
    // Set the context (this will be included in the output email)
    "identifier": "My company name",
    // Semi-colon separated list of email addresses to send email to
    "emailResultsTo": "test@zero.co.zip",
    // Only include a reservation if Days To Expire >= 30 (range 1)
    "range1min": 30,
    // Only include a reservation if Days To Expire < 37 (range 1)
    "range1max": 37,
    // Only include a reservation if Days To Expire >= 60 (range 2)
    "range2min": 60,
    // Only include a reservation if Days To Expire < 67 (range 2)
    "range2max": 67
}
```

In the example above, a reservation will be included should it expire within:

* 30 to 37 days
* 60 to 67 days

The intention is for this LogicApp to be invoked (i.e. via another LogicApp, based on a Recurrence trigger) once a week. The above ranges will then ensure only one email is sent during that week.

# Results

The `audit` and `monitor` modes result in fairly similar emails. The emails (of which the template was shamelessly copied from other Azure-esque notifications) are light/dark responsive, and scales as needed.

Sample `audit` email:

![image](https://user-images.githubusercontent.com/3426823/205324663-e8a8c3fa-a014-4dd4-97d4-611be7e8ff3b.png)
