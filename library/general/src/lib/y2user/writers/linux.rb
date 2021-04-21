require "yast2/execute"

module Y2User
  module Writers
    # Writes users and groups to the system using Yast2::Execute and standard
    # linux tools.
    #
    # NOTE: currently it only creates new users, removing or modifying users is
    # still not covered. No group management either.
    # NOTE: no plugin support yet
    # NOTE: no make for NIS server yet
    # NOTE: we need to check why nscd_passwd is relevant
    # NOTE: no support for the Yast::Users option no_skeleton
    # NOTE: no support for the Yast::Users chown_home=0 option (what is good for?)
    # NOTE: If the home directory already exists, yast-users still copies skel and everything else
    #   as usual. What exactly does useradd in that case? permissions, ownership, skel, 

    # TODO: other password attributes like #maximum_age, #inactivity_period, etc.
    # TODO: no authorized keys yet
    # TODO: no support yet for useradd_postcommands (USERADD_CMD)
    class Linux
      # @param configuration [Y2User::Configuration] configuration containing the users
      #   and groups that should exist in the system after writing
      # NOTE: right now we consider the system is empty, but in the future we
      #   might need another configuration describing the initial state, so we can
      #   compare and know what changes are actually needed
      def write(configuration) #, origin: Y2User::Configuration.system)
        configuration.users.map { |user| add_user(user) }
      end

    private

      def add_user(user)
        # write /etc/passwd
        useradd pepe --uid X --gid Y --shell S --home-dir H --comment GECOS

        # home_wanted?
        # create_home(btrfs_subvol, copy_skel)
        --create-home 
        --btrfs-subvolume-home

        # write shadow file
        --password (may be risky because the encrypted password is visible as part of the process name)

        --expiredate password.account_expiration

        # TODO: remove the passwd cache for nscd (bug 24748, 41648)
      end
    end
  end
end
