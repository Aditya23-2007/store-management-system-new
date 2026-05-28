<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%@include file="includes/auth.jsp"%>

<%
    request.setAttribute("activePage", "users");
    request.setAttribute("pageTitle", "Users Management");
%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Users Management</title>

    <%@include file="includes/header.jsp"%>

</head>

<body>

<div class="app">

    <%@include file="includes/sidebar.jsp"%>

    <main class="main">

        <%@include file="includes/topbar.jsp"%>

        <div class="users-layout">

            <!-- ========================================= -->
            <!-- ADD USER FORM -->
            <!-- ========================================= -->

            <div class="cat-form-card">

                <div class="modal-title">
                    Add New User
                </div>

                <% if(request.getAttribute("error") != null) { %>
                    <div class="access-alert" style="margin-bottom: 15px; background: #fef2f2; color: #991b1b; border-color: #fee2e2; padding: 10px; border-radius: 6px; font-size: 14px; border: 1px solid;">
                        <%= request.getAttribute("error") %>
                    </div>
                <% } %>

                <form action="users" method="post">

                    <div class="form-group">
                        <label>Full Name</label>

                        <input type="text"
                               class="form-control"
                               name="full_name"
                               placeholder="Enter full name"
                               required>
                    </div>

                    <div class="form-group">
                        <label>User Name</label>

                        <input type="text"
                               class="form-control"
                               name="username"
                               placeholder="Enter username"
                               required>
                    </div>

                    <div class="form-group">
                        <label>Email</label>

                        <input type="email"
                               class="form-control"
                               name="email"
                               placeholder="Enter email address">
                    </div>

                    <div class="form-group">
                        <label>Password</label>

                        <input type="password"
                               class="form-control"
                               name="password"
                               placeholder="Enter password"
                               autocomplete="new-password"
                               required>
                    </div>

                    <div class="form-group">
                        <label>Role</label>

                        <select class="form-control"
                                name="role">

                            <option value="admin">
                                admin
                            </option>

                            <option value="user">
                                user
                            </option>

                            <option value="director">
                                director
                            </option>

                            <option value="store">
                                store
                            </option>

                            <option value="accounts">
                                accounts
                            </option>

                        </select>
                    </div>

                    <div class="form-group">
                        <label>Address</label>

                        <textarea class="form-control"
                                  name="address"
                                  rows="3"
                                  placeholder="Enter address"></textarea>
                    </div>

                    <button type="submit"
                            class="btn-primary"
                            style="width:100%;
                                   justify-content:center">

                        Add User

                    </button>

                </form>

            </div>

            <!-- ========================================= -->
            <!-- USERS TABLE -->
            <!-- ========================================= -->

            <div>

                <div class="table-search"
                     style="margin-bottom:16px">

                    <span>🔍</span>

                    <input type="text"
                           oninput="filterTable('users-table',this.value)"
                           placeholder="Search users...">

                </div>

                <div class="data-table">

                    <table id="users-table">

                        <thead>

                        <tr>

                            <th>ID</th>
                            <th>Full Name</th>
                            <th>Username</th>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Action</th>

                        </tr>

                        </thead>

                        <tbody>

                        <%
                            try {

                                java.sql.Connection con =
                                    com.store.util.DBConnection.getConnection();

                                java.sql.PreparedStatement ps =
                                    con.prepareStatement(
                                        "SELECT * FROM users ORDER BY id DESC"
                                    );

                                java.sql.ResultSet rs =
                                    ps.executeQuery();

                                while(rs.next()) {
                        %>

                        <tr>

                            <td>
                                <%= rs.getInt("id") %>
                            </td>

                            <td>
                                <%= rs.getString("full_name") %>
                            </td>

                            <td>
                                <%= rs.getString("username") %>
                            </td>

                            <td>
                                <%= rs.getString("email") %>
                            </td>

                            <td>

                                <span class="status active-status">

                                    <%= rs.getString("role") %>

                                </span>

                            </td>

                             <td>
                                 <button class="action-link delete"
                                         onclick="deleteUser(<%= rs.getInt("id") %>)">
                                     Delete
                                 </button>
                             </td>

                        </tr>

                        <%
                                }

                            } catch(Exception e) {
                        %>

                        <tr>

                            <td colspan="6"
                                style="color:red;
                                       text-align:center">

                                Error Loading Users:
                                <%= e.getMessage() %>

                            </td>

                        </tr>

                        <%
                            }
                        %>

                        </tbody>

                    </table>

                </div>

            </div>

        </div>

    </main>

</div>

<script>

    function filterTable(tableId, searchText) {

        let filter =
            searchText.toLowerCase();

        let rows =
            document.querySelectorAll(
                "#" + tableId + " tbody tr"
            );

        rows.forEach(row => {

            let text =
                row.innerText.toLowerCase();

            row.style.display =
                text.includes(filter)
                ? ""
                : "none";
        });
    }

    function deleteUser(id) {
        if(confirm("Delete this user?")) {
            window.location.href = "users?delete=" + id;
        }
    }

</script>

</body>
</html>