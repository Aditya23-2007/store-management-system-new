STORE MANAGEMENT WEB APPLICATION
Technology: Java JSP + Servlet + MySQL + Maven + Tomcat

HOW TO RUN IN NETBEANS
1. Install Apache NetBeans, JDK 11 or above, MySQL Server and Apache Tomcat 9.
2. Open MySQL and run database/store_db.sql.
3. Edit DB credentials in:
   src/main/java/com/store/util/DBConnection.java
   Default username=root and password=root.
4. Open NetBeans.
5. File -> Open Project -> select StoreManagementWebApp folder.
6. Right click project -> Clean and Build.
7. Right click project -> Run.
8. Select Apache Tomcat server if asked.
9. Open browser:
   http://localhost:8080/StoreManagementWebApp/

DEFAULT LOGIN
Username: admin
Password: admin123

MODULES INCLUDED
Login, Dashboard, Products, Customers, Suppliers, Billing, Sales Report, Logout.

NOTE
This is an educational project. Passwords are stored in plain text for simplicity. For production, use hashed passwords and stronger validation.
