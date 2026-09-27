<%@ Page Language="C#" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>

<script runat="server">

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            lblLoggedInUser.Text = Server.HtmlEncode(Context.User.Identity.Name);
        }
    }

    protected void CreateEmployee_Click(object sender, EventArgs e)
    {
        pnlResult.Visible = false;
        lblResult.Text = "";

        string firstName = txtFirstName.Text.Trim();
        string lastName = txtLastName.Text.Trim();
        string department = ddlDepartment.SelectedValue;
        string jobTitle = txtJobTitle.Text.Trim();
        string startDate = txtStartDate.Text.Trim();

        if (String.IsNullOrWhiteSpace(firstName))
        {
            ShowError("First name is required.");
            return;
        }

        if (String.IsNullOrWhiteSpace(lastName))
        {
            ShowError("Last name is required.");
            return;
        }

        if (String.IsNullOrWhiteSpace(department))
        {
            ShowError("Department is required.");
            return;
        }

        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();

            psi.FileName =
                @"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe";

            psi.Arguments =
                "-NoProfile -NonInteractive -ExecutionPolicy Bypass " +
                "-Command \"" +
                "& 'C:\\Scripts\\New-NorthStarEmployee.ps1' " +
                "-FirstName $env:NS_FIRSTNAME " +
                "-LastName $env:NS_LASTNAME " +
                "-Department $env:NS_DEPARTMENT " +
                "-JobTitle $env:NS_JOBTITLE " +
                "-StartDate $env:NS_STARTDATE" +
                "\"";

            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.CreateNoWindow = true;

            psi.EnvironmentVariables["NS_FIRSTNAME"] = firstName;
            psi.EnvironmentVariables["NS_LASTNAME"] = lastName;
            psi.EnvironmentVariables["NS_DEPARTMENT"] = department;
            psi.EnvironmentVariables["NS_JOBTITLE"] = jobTitle;
            psi.EnvironmentVariables["NS_STARTDATE"] = startDate;

            Process process = new Process();
            process.StartInfo = psi;
            process.Start();

            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();

            process.WaitForExit();

            if (process.ExitCode == 0)
            {
                ShowSuccess(
                    GetOutputValue(output, "Username:"),
                    GetOutputValue(output, "Department:"),
                    GetOutputValue(output, "Department Group:"),
                    GetOutputValue(output, "Home Folder:")
                );

                ClearForm();
            }
            else
            {
                string cleanError = String.IsNullOrWhiteSpace(error)
                    ? output
                    : error;

                ShowError(
                    "Employee provisioning failed.<br /><br />" +
                    Server.HtmlEncode(cleanError)
                );
            }
        }
        catch (Exception ex)
        {
            ShowError(
                "Employee provisioning failed.<br /><br />" +
                Server.HtmlEncode(ex.Message)
            );
        }
    }

    private string GetOutputValue(string output, string label)
    {
        string[] lines = output.Split(
            new string[] { "\r\n", "\n" },
            StringSplitOptions.RemoveEmptyEntries
        );

        foreach (string line in lines)
        {
            string trimmed = line.Trim();

            if (trimmed.StartsWith(label, StringComparison.OrdinalIgnoreCase))
            {
                return trimmed.Substring(label.Length).Trim();
            }
        }

        return "";
    }

    private void ShowSuccess(
        string username,
        string department,
        string departmentGroup,
        string homeFolder)
    {
        pnlResult.Visible = true;
        pnlResult.CssClass = "result success";

        StringBuilder html = new StringBuilder();

        html.Append("<div class='result-title'>Employee Created Successfully</div>");
        html.Append("<div class='result-grid'>");

        html.Append("<div class='result-label'>Username</div>");
        html.Append("<div>" + Server.HtmlEncode(username) + "</div>");

        html.Append("<div class='result-label'>Department</div>");
        html.Append("<div>" + Server.HtmlEncode(department) + "</div>");

        html.Append("<div class='result-label'>Department Group</div>");
        html.Append("<div>" + Server.HtmlEncode(departmentGroup) + "</div>");

        html.Append("<div class='result-label'>Home Folder</div>");
        html.Append("<div>" + Server.HtmlEncode(homeFolder) + "</div>");

        html.Append("</div>");

        lblResult.Text = html.ToString();
    }

    private void ShowError(string message)
    {
        pnlResult.Visible = true;
        pnlResult.CssClass = "result error";

        lblResult.Text =
            "<div class='result-title'>Provisioning Failed</div>" +
            "<div class='error-text'>" +
            message +
            "</div>";
    }

    private void ClearForm()
    {
        txtFirstName.Text = "";
        txtLastName.Text = "";
        ddlDepartment.SelectedIndex = 0;
        txtJobTitle.Text = "";
        txtStartDate.Text = "";
    }

</script>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>NorthStar Employee Onboarding</title>

    <style>
        body {
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f4f6f8;
            margin: 0;
            padding: 0;
        }

        .page {
            max-width: 760px;
            margin: 40px auto;
            padding: 0 20px;
        }

        .header {
            margin-bottom: 24px;
        }

        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }

        .subtitle,
        .signed-in {
            color: #666;
            margin-top: 8px;
        }

        .signed-in {
            font-size: 13px;
        }

        .card {
            background: white;
            border: 1px solid #d9dde2;
            border-radius: 8px;
            padding: 28px;
            box-shadow: 0 2px 5px rgba(0,0,0,.06);
        }

        .field {
            margin-bottom: 18px;
        }

        .field label {
            display: block;
            font-weight: 600;
            margin-bottom: 7px;
        }

        .input {
            width: 100%;
            box-sizing: border-box;
            padding: 11px;
            border: 1px solid #aeb5bd;
            border-radius: 4px;
            font-size: 15px;
        }

        .button {
            width: 100%;
            padding: 13px;
            margin-top: 8px;
            border: none;
            border-radius: 4px;
            background: #315d8a;
            color: white;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }

        .result {
            margin-top: 24px;
            padding: 22px;
            border-radius: 6px;
        }

        .success {
            background: #eef8f0;
            border: 1px solid #9ac8a3;
        }

        .error {
            background: #fff1f1;
            border: 1px solid #d59a9a;
        }

        .result-title {
            font-size: 19px;
            font-weight: 600;
            margin-bottom: 16px;
        }

        .result-grid {
            display: grid;
            grid-template-columns: 160px 1fr;
            row-gap: 10px;
        }

        .result-label {
            font-weight: 600;
        }

        .error-text {
            white-space: pre-wrap;
            font-family: Consolas, monospace;
            font-size: 13px;
        }
    </style>
</head>

<body>
<form id="form1" runat="server">

<div class="page">

    <div class="header">
        <h1>NorthStar Employee Onboarding</h1>

        <div class="subtitle">
            Create a new NorthStar domain employee account.
        </div>

        <div class="signed-in">
            Signed in as:
            <strong>
                <asp:Label ID="lblLoggedInUser" runat="server" />
            </strong>
        </div>
    </div>

    <div class="card">

        <div class="field">
            <label>First Name</label>
            <asp:TextBox ID="txtFirstName" runat="server" CssClass="input" />
        </div>

        <div class="field">
            <label>Last Name</label>
            <asp:TextBox ID="txtLastName" runat="server" CssClass="input" />
        </div>

        <div class="field">
            <label>Department</label>

            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="input">
                <asp:ListItem Text="Select Department" Value="" />
                <asp:ListItem Text="Shipping" Value="Shipping" />
                <asp:ListItem Text="Accounting" Value="Accounting" />
                <asp:ListItem Text="Human Resources" Value="Human Resources" />
                <asp:ListItem Text="Executives" Value="Executives" />
                <asp:ListItem Text="I.T" Value="I.T" />
            </asp:DropDownList>
        </div>

        <div class="field">
            <label>Job Title</label>
            <asp:TextBox ID="txtJobTitle" runat="server" CssClass="input" />
        </div>

        <div class="field">
            <label>Start Date</label>
            <asp:TextBox
                ID="txtStartDate"
                runat="server"
                CssClass="input"
                TextMode="Date" />
        </div>

        <asp:Button
            ID="btnCreateEmployee"
            runat="server"
            Text="Create Employee"
            CssClass="button"
            OnClick="CreateEmployee_Click" />

        <asp:Panel ID="pnlResult" runat="server" Visible="false">
            <asp:Label ID="lblResult" runat="server" />
        </asp:Panel>

    </div>
</div>

</form>
</body>
</html>
