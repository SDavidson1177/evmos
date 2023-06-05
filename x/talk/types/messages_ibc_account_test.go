package types

import (
	"testing"
)

func TestMsgSendIbcAccount_ValidateBasic(t *testing.T) {
	// tests := []struct {
	// 	name string
	// 	msg  MsgSendIbcAccount
	// 	err  error
	// }{
	// 	{
	// 		name: "invalid address",
	// 		msg: MsgSendIbcAccount{
	// 			Creator:          "invalid_address",
	// 			Port:             "port",
	// 			ChannelID:        "channel-0",
	// 			TimeoutTimestamp: 100,
	// 		},
	// 		err: sdkerrors.ErrInvalidAddress,
	// 	}, {
	// 		name: "invalid port",
	// 		msg: MsgSendIbcAccount{
	// 			Creator:          sample.AccAddress(),
	// 			Port:             "",
	// 			ChannelID:        "channel-0",
	// 			TimeoutTimestamp: 100,
	// 		},
	// 		err: sdkerrors.ErrInvalidRequest,
	// 	}, {
	// 		name: "invalid channel",
	// 		msg: MsgSendIbcAccount{
	// 			Creator:          sample.AccAddress(),
	// 			Port:             "port",
	// 			ChannelID:        "",
	// 			TimeoutTimestamp: 100,
	// 		},
	// 		err: sdkerrors.ErrInvalidRequest,
	// 	}, {
	// 		name: "invalid timeout",
	// 		msg: MsgSendIbcAccount{
	// 			Creator:          sample.AccAddress(),
	// 			Port:             "port",
	// 			ChannelID:        "channel-0",
	// 			TimeoutTimestamp: 0,
	// 		},
	// 		err: sdkerrors.ErrInvalidRequest,
	// 	}, {
	// 		name: "valid message",
	// 		msg: MsgSendIbcAccount{
	// 			Creator:          sample.AccAddress(),
	// 			Port:             "port",
	// 			ChannelID:        "channel-0",
	// 			TimeoutTimestamp: 100,
	// 		},
	// 	},
	// }
	// for _, tt := range tests {
	// 	t.Run(tt.name, func(t *testing.T) {
	// 		err := tt.msg.ValidateBasic()
	// 		if tt.err != nil {
	// 			require.ErrorIs(t, err, tt.err)
	// 			return
	// 		}
	// 		require.NoError(t, err)
	// 	})
	// }
}
