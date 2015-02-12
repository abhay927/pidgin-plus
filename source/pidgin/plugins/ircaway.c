/*
 * IRC Away Plugin
 *
 * Copyright 2012, 2014 Renato Silva
 * Licensed under GNU GPLv2 or later
 *
 */

#include <internal.h>
#include <version.h>
#include <purple.h>
#include <gtkplugin.h>

#define NAME "ircaway"
#define IRC_ID "prpl-irc"
#define ID "gtk.renatosilva." NAME
#define SUFFIX_PREFERENCE ID ".suffix"
#define DEFAULT_SUFFIX "Away"

static gboolean plugin_load(PurplePlugin *plugin);
static gboolean plugin_unload(PurplePlugin *plugin);
static void status_changed(PurpleAccount *account, PurpleStatus *status);

static PurpleAccountUiOps account_uiops = {
	NULL,             /* notify_added          */
	status_changed,   /* status_changed        */
	NULL,             /* request_add           */
	NULL,             /* request_authorize     */
	NULL,             /* close_account_request */
	NULL,             /* _purple_reserved1     */
	NULL,             /* _purple_reserved1     */
	NULL,             /* _purple_reserved1     */
	NULL              /* _purple_reserved1     */
};

static PurplePluginInfo info = {
	PURPLE_PLUGIN_MAGIC,
	PURPLE_MAJOR_VERSION,
	PURPLE_MINOR_VERSION,
	PURPLE_PLUGIN_STANDARD,
	PIDGIN_PLUGIN_TYPE,
	0,
	NULL,
	PURPLE_PRIORITY_DEFAULT,
	ID,
	NULL,
	"2015.2.12",
	NULL,
	NULL,
	"Renato Silva",
	"http://launchpad.net/pidgin-ircaway",
	plugin_load,
	plugin_unload,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};

static PurpleConversation *dummy_conversation(PurpleAccount *account) {
	PurpleConversation *dummy;
	dummy = g_new0(PurpleConversation, 1);
	dummy->type = PURPLE_CONV_TYPE_IM;
	dummy->account = account;
	return dummy;
}

static char *remove_union(const char *of, const char *with) {

	int oix = 0;
	int wix = 0;
	int ix = -1;

	if (of == NULL)
		return NULL;

	while (of[oix] != '\0') {
		if (of[oix] == with[wix]) {
			if (wix == 0)
				ix = oix;
			wix++;
		} else if (wix > 0) {
			wix = 0;
		}
		oix++;
	}
	if (ix < 1)
		ix = oix;
	return g_strndup(of, ix);
}

static void change_nick(PurpleAccount *account, char *new_nick) {

	PurpleConversation *conversation;
	char *nick_command;
	char *error;

	if (new_nick == NULL)
		return;

	conversation = dummy_conversation(account);
	nick_command = g_strconcat("nick ", new_nick, NULL);

	if (purple_cmd_do_command(conversation, nick_command, nick_command, &error) != PURPLE_CMD_STATUS_OK) {
		purple_debug_warning(NAME, "Failed to execute %s\n", nick_command);
		g_free(error);
	}

	g_free(conversation);
	g_free(nick_command);
}

static void status_changed(PurpleAccount *account, PurpleStatus *status) {

	const char *suffix;
	char *old_nick;
	char *new_nick;

	if (!g_str_equal(purple_account_get_protocol_id(account), IRC_ID))
		return;

	suffix = purple_account_get_string(account, SUFFIX_PREFERENCE, DEFAULT_SUFFIX);
	old_nick = (char *) purple_connection_get_display_name(purple_account_get_connection(account));

	if (purple_status_is_available(status)) {
		new_nick = remove_union(old_nick, suffix);
		if (!g_ascii_strcasecmp(new_nick, old_nick))
			return;
	} else {
		if (g_str_has_suffix (old_nick, suffix))
			return;
		new_nick = g_strconcat(old_nick, suffix, NULL);
	}
	change_nick(account, new_nick);
	g_free(new_nick);
}

static gboolean plugin_load(PurplePlugin *plugin) {

	PurplePlugin *irc;
	PurplePluginProtocolInfo *irc_info;
	PurpleAccountOption *option;

	irc = purple_plugins_find_with_id(IRC_ID);
	if (NULL == irc)
		return FALSE;

	irc_info = PURPLE_PLUGIN_PROTOCOL_INFO(irc);
	if (NULL == irc_info)
		return FALSE;

	option = purple_account_option_string_new(_("Nick away suffix"), SUFFIX_PREFERENCE, DEFAULT_SUFFIX);
	irc_info->protocol_options = g_list_append(irc_info->protocol_options, option);
	purple_accounts_set_ui_ops(&account_uiops);
	return TRUE;
}

static gboolean plugin_unload(PurplePlugin *plugin) {

	PurplePlugin *irc;
	PurplePluginProtocolInfo *irc_info;
	GList *options;

	irc = purple_plugins_find_with_id(IRC_ID);
	if (NULL == irc)
		return FALSE;

	irc_info = PURPLE_PLUGIN_PROTOCOL_INFO(irc);
	if (NULL == irc_info)
		return FALSE;

	options = irc_info->protocol_options;

	while (NULL != options) {
		PurpleAccountOption *option = (PurpleAccountOption *) options->data;
		if (g_str_has_prefix(purple_account_option_get_setting(option), ID ".")) {
			options = g_list_delete_link (options, options);
			purple_account_option_destroy(option);
		} else {
			options = g_list_next(options);
		}
	}
	return TRUE;
}

static void init_plugin(PurplePlugin *plugin) {
	info.dependencies = g_list_append(info.dependencies, IRC_ID);
	info.name = _("IRC Away");
	info.summary = _("IRC Away Nick");
	info.description = _("Changes your nick to indicate you are away.");
}

PURPLE_INIT_PLUGIN(NAME, init_plugin, info)
