using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartGuard.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class DeleteBehaviorForEventForeigns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Alerts_Devices_DeviceId",
                table: "Alerts");

            migrationBuilder.DropForeignKey(
                name: "FK_Alerts_FaceDetectionEvents_LinkedEventId",
                table: "Alerts");

            migrationBuilder.DropForeignKey(
                name: "FK_FaceDetectionEvents_Devices_DeviceId",
                table: "FaceDetectionEvents");

            migrationBuilder.DropForeignKey(
                name: "FK_FaceDetectionEvents_KnownPersons_PersonId",
                table: "FaceDetectionEvents");

            migrationBuilder.DropForeignKey(
                name: "FK_Recordings_Devices_DeviceId",
                table: "Recordings");

            migrationBuilder.DropForeignKey(
                name: "FK_ScheduledRecordings_Devices_DeviceId",
                table: "ScheduledRecordings");

            migrationBuilder.DropForeignKey(
                name: "FK_UserDeviceAccesses_Devices_DeviceId",
                table: "UserDeviceAccesses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserNotificationPreferences_KnownPersons_PersonId",
                table: "UserNotificationPreferences");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "UserDeviceAccesses",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "ScheduledRecordings",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "Recordings",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "FaceDetectionEvents",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "Alerts",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddForeignKey(
                name: "FK_Alerts_Devices_DeviceId",
                table: "Alerts",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Alerts_FaceDetectionEvents_LinkedEventId",
                table: "Alerts",
                column: "LinkedEventId",
                principalTable: "FaceDetectionEvents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_FaceDetectionEvents_Devices_DeviceId",
                table: "FaceDetectionEvents",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_FaceDetectionEvents_KnownPersons_PersonId",
                table: "FaceDetectionEvents",
                column: "PersonId",
                principalTable: "KnownPersons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Recordings_Devices_DeviceId",
                table: "Recordings",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_ScheduledRecordings_Devices_DeviceId",
                table: "ScheduledRecordings",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserDeviceAccesses_Devices_DeviceId",
                table: "UserDeviceAccesses",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserNotificationPreferences_KnownPersons_PersonId",
                table: "UserNotificationPreferences",
                column: "PersonId",
                principalTable: "KnownPersons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Alerts_Devices_DeviceId",
                table: "Alerts");

            migrationBuilder.DropForeignKey(
                name: "FK_Alerts_FaceDetectionEvents_LinkedEventId",
                table: "Alerts");

            migrationBuilder.DropForeignKey(
                name: "FK_FaceDetectionEvents_Devices_DeviceId",
                table: "FaceDetectionEvents");

            migrationBuilder.DropForeignKey(
                name: "FK_FaceDetectionEvents_KnownPersons_PersonId",
                table: "FaceDetectionEvents");

            migrationBuilder.DropForeignKey(
                name: "FK_Recordings_Devices_DeviceId",
                table: "Recordings");

            migrationBuilder.DropForeignKey(
                name: "FK_ScheduledRecordings_Devices_DeviceId",
                table: "ScheduledRecordings");

            migrationBuilder.DropForeignKey(
                name: "FK_UserDeviceAccesses_Devices_DeviceId",
                table: "UserDeviceAccesses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserNotificationPreferences_KnownPersons_PersonId",
                table: "UserNotificationPreferences");

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "UserDeviceAccesses",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "ScheduledRecordings",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "Recordings",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "FaceDetectionEvents",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "DeviceId",
                table: "Alerts",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Alerts_Devices_DeviceId",
                table: "Alerts",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Alerts_FaceDetectionEvents_LinkedEventId",
                table: "Alerts",
                column: "LinkedEventId",
                principalTable: "FaceDetectionEvents",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_FaceDetectionEvents_Devices_DeviceId",
                table: "FaceDetectionEvents",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_FaceDetectionEvents_KnownPersons_PersonId",
                table: "FaceDetectionEvents",
                column: "PersonId",
                principalTable: "KnownPersons",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Recordings_Devices_DeviceId",
                table: "Recordings",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ScheduledRecordings_Devices_DeviceId",
                table: "ScheduledRecordings",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserDeviceAccesses_Devices_DeviceId",
                table: "UserDeviceAccesses",
                column: "DeviceId",
                principalTable: "Devices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserNotificationPreferences_KnownPersons_PersonId",
                table: "UserNotificationPreferences",
                column: "PersonId",
                principalTable: "KnownPersons",
                principalColumn: "Id");
        }
    }
}
