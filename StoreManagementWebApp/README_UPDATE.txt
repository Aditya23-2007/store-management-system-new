StoreManagementWebApp Updated Build

Major updates added:
1. Products, Categories, Suppliers, Orders/Billing, Users, Requirements, Approvals, Purchase Orders, Receive Items, Invoices/Scans, Payments and Reports pages are wired with database tables.
2. Invoice/Bill scan upload module added.
3. Uploaded invoice PDF/JPG/PNG files are saved in: src/main/webapp/uploads/invoices/
4. Invoice file path and JSON metadata are saved in MySQL table: invoice_documents.
5. Fresh SQL script is available at: database/store_db.sql

Setup:
1. Import database/store_db.sql in MySQL Workbench.
2. Check password in src/main/java/com/store/util/DBConnection.java.
3. Open project in NetBeans.
4. Clean and Build.
5. Run with Tomcat 9.
6. Login: admin / admin123

Important URLs:
http://localhost:8080/StoreManagementWebApp/login.jsp
http://localhost:8080/StoreManagementWebApp/dashboard.jsp
http://localhost:8080/StoreManagementWebApp/invoices.jsp

After UI updates, press Ctrl+F5 in browser.

2026-05-19 update: Added department-wise item issue/transfer and scrap item tracking.
New pages:
- issueItems.jsp: transfer single/bulk item quantities to departments with mandatory remarks.
- scrapItems.jsp: record unusable/scrap items with reason, condition, authority, and remarks.
New database tables:
- departments
- item_transfers
- scrap_items
Reports updated with Department Transfers and Scrap Items categories for PDF/Excel export.
