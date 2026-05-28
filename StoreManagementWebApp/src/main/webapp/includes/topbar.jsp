<%@page pageEncoding="UTF-8"%>
<div class="topbar">
  <div>
    <h1 class="topbar-title"><%= request.getAttribute("pageTitle") %></h1>
    <div class="role-line">
      Logged in as:
      <strong><%= session.getAttribute("username") %></strong>
      (<%= session.getAttribute("role") %>)
    </div>
  </div>

  <div class="topbar-right">
    <div class="auto-logout-control" title="Automatic logout time after no activity">
      <i class="bi bi-clock-history"></i>
      <label for="autoLogoutMinutes">Auto logout</label>
      <select id="autoLogoutMinutes" aria-label="Auto logout minutes">
        <option value="10">10 min</option>
        <option value="15">15 min</option>
        <option value="20">20 min</option>
        <option value="30">30 min</option>
        <option value="45">45 min</option>
        <option value="60">60 min</option>
        <option value="75">75 min</option>
        <option value="90">90 min</option>
      </select>
    </div>
    <div class="search-box"><span>🔍</span><input type="text" placeholder="Search..." /></div>
    <div class="notif-btn">🔔<span class="notif-badge">3</span></div>
  </div>
</div>
<% if ("denied".equals(request.getParameter("access"))) { %>
  <div class="access-alert">
    You do not have permission to open that page for your current role.
  </div>
<% } %>
