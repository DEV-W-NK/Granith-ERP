class SupabaseSelects {
  static const String userProfile =
      'id,email,displayName,display_name,photoUrl,photo_url,status,permissions,'
      'role,clientAccountId,client_account_id,clientAccountName,'
      'client_account_name,username,login_username,internalLoginEmail,'
      'internal_login_email,authProvider,auth_provider,employeeId,'
      'employee_id,employeeName,employee_name';

  static const String clientAccount =
      'id,name,ownerEmail,owner_email,contactEmail,contact_email,contactPhone,'
      'contact_phone,status,notes,portalAccessStatus,portal_access_status,'
      'portalAuthUserId,portal_auth_user_id,portalInvitedAt,portal_invited_at,'
      'portalLastAccessAt,portal_last_access_at,created_at,updated_at';

  static const String systemSettings =
      'id,workspace_name,workspace_tagline,dashboard_greeting_title,'
      'dashboard_greeting_subtitle,ai_assistant_preview_enabled,'
      'compact_navigation,support_email,support_phone,'
      'client_portal_welcome_message,client_portal_show_budgets,'
      'client_portal_show_budget_values,client_portal_show_current_costs,'
      'time_clock_enabled,time_clock_geofence_required,'
      'time_clock_store_rejected_attempts,'
      'time_clock_inpi_registration_number,time_clock_employer_name,'
      'time_clock_employer_document,time_clock_timezone,updated_at';

  static const String usageStats =
      'id,tenantId,projectRef,totalReads,totalWrites,totalApiRequests,'
      'totalRestRequests,totalAuthRequests,totalStorageRequests,'
      'totalRealtimeRequests,databaseUsedMB,storageUsedMB,aiRequests,'
      'periodStart,periodEnd,dailyOperations,peakDayOperations,sourceLabel,'
      'lastSyncedAt';

  static const String financialTransaction =
      'id,description,amount,type,status,origin,category,dueDate,paymentDate,'
      'projectId,supplierId,referenceId,createdBy,createdAt,updatedAt,notes';

  static const String financialDashboard =
      'id,description,amount,type,status,dueDate,paymentDate,createdAt';

  static const String projectDashboard =
      'id,name,status,budget,currentCost,startDate,endDate';

  static const String projectReport = 'id,name,budget';

  static const String clientPortalProject =
      'id,name,client,description,status,startDate,endDate,location,tags,'
      'teamSize,imageUrl,clientAccountId,client_account_id,clientAccountName,'
      'client_account_name,estimatedProgress,estimated_progress,'
      'measurementCount,measurement_count,lastMeasurementAt,'
      'last_measurement_at';

  static const String inventoryReport = 'id,name,unit,quantity,minQuantity';

  static const String dailyLogReport = 'id,projectName,date,manpower';
}
