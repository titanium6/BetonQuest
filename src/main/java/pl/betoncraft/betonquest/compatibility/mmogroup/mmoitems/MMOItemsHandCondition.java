package pl.betoncraft.betonquest.compatibility.mmogroup.mmoitems;

import net.Indyuce.mmoitems.MMOItems;
import net.Indyuce.mmoitems.api.Type;
import net.Indyuce.mmoitems.manager.TypeManager;
import net.mmogroup.mmolib.api.item.NBTItem;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.PlayerInventory;
import pl.betoncraft.betonquest.Instruction;
import pl.betoncraft.betonquest.api.Condition;
import pl.betoncraft.betonquest.exceptions.InstructionParseException;
import pl.betoncraft.betonquest.exceptions.QuestRuntimeException;
import pl.betoncraft.betonquest.utils.PlayerConverter;

import java.util.ArrayList;

public class MMOItemsHandCondition extends Condition {

    private final Type itemType;
    private final String itemID;
    private int amount = 1;
    private final boolean offhand;

    public MMOItemsHandCondition(final Instruction instruction) throws InstructionParseException {
        super(instruction, true);

        final TypeManager typeManager = MMOItems.plugin.getTypes();
        itemType = typeManager.get(instruction.next());
        itemID = instruction.next();

        final ArrayList<Integer> potentialAmount = instruction.getAllNumbers();
        if (!potentialAmount.isEmpty()) {
            amount = potentialAmount.get(0);
        }

        offhand = instruction.hasArgument("offhand");
    }

    @Override
    protected Boolean execute(final String playerID) throws QuestRuntimeException {
        final PlayerInventory inv = PlayerConverter.getPlayer(playerID).getInventory();
        final ItemStack item = offhand ?  inv.getItemInOffHand() : inv.getItemInMainHand();

        final NBTItem realItemNBT = NBTItem.get(item);
        final String realItemType = realItemNBT.getString("MMOITEMS_ITEM_TYPE");
        final String realItemID = realItemNBT.getString("MMOITEMS_ITEM_ID");

        return realItemID.equalsIgnoreCase(itemID) && realItemType.equalsIgnoreCase(itemType.getId()) && item.getAmount() == amount;
    }
}
